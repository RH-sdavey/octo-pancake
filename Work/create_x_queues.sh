#!/usr/bin/env bash


## move the main code into function so you can run it in backgroud + 
## little modification to be able set start and end point in list
function openshift {
for (( x=$1 ; x <= $2 ; x++ ));do
    if [[ "${DEL}" -eq 1 ]]; then
        oc delete address seantest-addr.${STEM}${x}   # can change this value to correct 'short' addr space name ( and value below in metadata
    else

        oc --as=developer create -f - << EOF
apiVersion: enmasse.io/v1alpha1
kind: Address
metadata:
    name: seantest-addr.${STEM}.${x}
spec:
    address: ${STEM}.${x}
    type: queue
    plan: pooled-queue
EOF
        
    fi
done
}

DEL=0
STEM=myqueue
BATCH=1 ## default size of BATCH set to 1 in case you don't specify it

declare -a POS
while [[ $# -gt 0 ]]
do
    case "$1" in
        --delete)
        DEL=1
        shift
        ;;
        --stem)
        STEM=$2
        shift
        shift
        ;;
## Added another option to set the size of BATCH
        --batch)
	BATCH=$2
	shift
	shift
	;;
	*)
        POS+=("$1")
        shift
        ;;
    esac
done

set -- "${POS[@]}"

COUNT=$1
START=0
COUNTER=0

## If you accidentaly use bigger BATCH than # of servers
[[ $COUNT -lt $BATCH ]] && BATCH=$COUNT

for (( i=0; i < ${COUNT}; i++ )) 
do
    (( COUNTER++ ))
    if [[ $COUNTER -eq $BATCH ]];then
        openshift $START $i &
        START=$(( i + 1 ))
        COUNTER=0
    fi
done

## Run the rest of servers which didn't fit into last whole BATCH
[[ $COUNTER != 0 ]] && openshift $START $(( COUNT - 1 )) &


## The waiting loop untill all processes in background finish (2 because grep will show also itself in ps)
NAME=$(basename $0)
while [[ $(ps -e |grep -c -i $NAME) -gt 2 ]];do
       	sleep 1
done

echo 'Finished :]'




