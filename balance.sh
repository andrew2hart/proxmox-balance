#!/bin/bash
# script to auto migrate VMs to lower loaded node
debug=1
baseload=4000

#get list of nodes, there is some other text to strip out

nodes=$(pvecm nodes| grep -Ev "^$|Member|-------|Nodeid|(local)"|awk '{print $3}')

if [ $debug = 1 ] ; then echo Found : $nodes ; fi

#get local node

mynode=$(pvecm nodes | grep "(local)" | awk '{print $3}')

if [ $debug = 1 ] ; then echo I am $mynode ; fi

#find our long term load
#load=$(cat /proc/loadavg | awk '{print $3*100}')
#find our cpu
load=$(ps -e -o %C | grep -v CPU | awk '{s+=$1} END {print s*100}')

if [ $debug = 1 ] ; then echo Load $load ; fi

#only look for VMs to migrate if higher than base load
if [ $load -gt $baseload ]
then
    if [ $debug = 1 ] ; then echo Load is high ; fi
    
    #find lower loaded node
    lowload=$load
    for node in $nodes
    do
        #aload=$(ssh $node cat /proc/loadavg | awk '{print $3*100}')
        aload=$(ssh $node ps -e -o %C | grep -v CPU | awk '{s+=$1} END {print s*100}')
        if [ $debug = 1 ] ; then echo Node $node is a load $aload ; fi
        if [ $aload -lt $lowload ]
        then
            lowload=$aload
            usenode=$node
        fi
    done

    #if we found a lower loaded node that is at half the load
    if [ $load -gt $(($lowload *2)) -a ! -z "$usenode"   ]
    then
        #find a vm to move...
        vms=$(qm list | grep running | awk '{print $1}')

        #we need to find the second highest cpu since moving the first will just result in another loaded node
        highestcpu=0
        highestvm=0
        secondcpu=0
        secondvm=0
        for vm in $vms
        do
            pid=$(pgrep -f $vm)
            if [ $debug = 1 ] ; then echo PID of VM $vm is $pid ; fi
            cpu=$(ps -p $pid -o %C | tail -1| awk '{print $1*100}')
            if [ $debug = 1 ] ; then echo CPU of VM $vm is $cpu ; fi
            
            if [ $cpu -gt $highestcpu ]
            then
                #save the previous highest
                secondcpu=$highestcpu
                secondvm=$highestvm
                #set the current highest
                highestcpu=$cpu
                highestvm=$vm
            fi
        done
        if [ $debug = 1 ] ; then echo Second vm is $secondvm at $secondcpu% ; fi

        vm=$secondvm    
        if [ $debug = 1 ] ; then echo VM to move is $vm ; fi
        #move it 
        if [ $vm != 0 -a ! -z $vm ]
        then
            if [ $debug = 1 ] ; then echo moving $vm to $usenode ; fi
            echo echo qm migrate $vm $usenode
        fi
    fi
fi
