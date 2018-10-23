#!/usr/bin/env bash

DEL=0
STEM=myqueue

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
        *)
        POS+=("$1")
        shift
        ;;
    esac
done
set -- "${POS[@]}"

COUNT=$1

for (( i=0; i < ${COUNT}; i++ )) 
do

  if [[ "${DEL}" -eq 1 ]]; then
     oc delete address seantest-addr.${STEM}${i}   # can change this value to correct 'short' addr space name ( and value below in metadata
  else

      oc --as=developer create -f - << EOF
apiVersion: enmasse.io/v1alpha1
kind: Address
metadata:
    name: seantest-addr.${STEM}.${i}
spec:
    address: ${STEM}.${i}
    type: queue
    plan: pooled-queue
EOF

  fi

done




