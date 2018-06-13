#!/bin/bash

# clean up script for all folders using SDScript#
if [ -d ./results ]
   then rm -R ./results
fi
if [ -d ./lssecfix-HARVESTER_V.1.9.1/OUT ]
   then rm -R ./lssecfix-HARVESTER_V.1.9.1/OUT/
fi
./main.sh

