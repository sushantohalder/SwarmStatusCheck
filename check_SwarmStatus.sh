#!/bin/bash


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                       Introduction
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# This script is made for a specific use-case i.e. to monitor the swarm quorum. So a docker swarm quorum is formed when there are more than half managers are up and woking.
# So this script returns Status 'Ok' when the all the managers are healthy and working, 'Warning' when any of the manager is unhealthy, And 'Critical' when more than half of the managers are unhealthy.
# In this script we have used 'docker node ls' command to know the status of the managers from any node. So if it is a worker node where we run  this script, then it returns 'Ok' as on woker node we cann't get the status of any node.

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                       License
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#     This plugin monitors the docker swarm quorum.
#     Copyright (C) 2018  Sushanto Halder

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




is_manager=$(docker info --format "{{json .Swarm.ControlAvailable }}") # checks if the node is worker node or not.

if [ "x$is_manager" = "xfalse" ]
then 
        is_active=$(docker info --format "{{json .Swarm.LocalNodeState }}") # check if the worker node is active or not.
        if [ "x$is_active" = 'x"active"' ]
        then
                echo "OK - This is an active workernode."
                exit 0
        fi
        echo "CRITICAL - Workernode not active"
        exit 2
fi

arr=( $(docker node ls --format {{.ManagerStatus}}) )
if [ $? -gt 0 ];
then
        echo "CRITICAL - Swarm is Unhealthy (not in quorum)"              # 'docker node ls' provides the status of manager nodes. It exits with exit code 2 if the swarm is unhealthy.
        exit 2
else
        reqStatus='Leader'
        altStatus='Reachable'
        fg=0
        for element in "${arr[@]}";
        do
                if [[ "$element" == "$reqStatus" || "$element" == "$altStatus" ]];
                then
                        fg=$((fg+1))                                       # increases the value of fg by one each time it encounters a reachable manager or the leader.
                fi
        done
        n=${#arr[@]}                                                       # n is the number of manager nodes in the swarm quorum.
        if [ "$n" -gt "$fg" ];
        then
                n=$((n/2))
                if [ "$fg" -gt "$n" ];
                then
                        echo "WARNING - Some manager is down"              # if any of the manager is down then it returns a warning
                        exit 1
                else
                        echo "CRITICAL - Swarm is Unhealthy (not in quorum)"  # if more than half of the managers are unhealthy, then it shows that the swarm cluster is in Critical state.
                        exit 2
                fi
        else
                echo "OK - Swarm is Healthy (in quorum)"
                exit 0
        fi
fi
