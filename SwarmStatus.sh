#!/bin/bash

arr=( $(docker node ls --format {{.ManagerStatus}}) )
if [ $? -gt 0 ];
then
        echo "NOT OK"
        exit 1
else
        reqStatus='Leader'
        altStatus='Reachable'
        fg=0
        for element in "${arr[@]}";
        do
                if [[ "$element" == "$reqStatus" || "$element" == "$altStatus" ]];
                then
                        fg=$((fg+1))
                fi
        done
        n=${#arr[@]}
        n=$((n/2))
        if [ "$fg" -gt "$n" ];
        then
                echo "OK"
                exit 0
        else
                echo "NOT OK"
                exit 1
        fi
fi