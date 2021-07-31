#!/bin/bash
#Show Approximate Vote Credits

pushd `dirname ${0}` > /dev/null || exit 1

CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

echo -e "${RED}"
echo -e "Vote-Credits Required ${CYAN}"

echo $(solana vote-account /root/vote-account-keypair.json | grep -A 4 History | grep -A 2 epoch | grep credits/slots | cut -d ' ' -f 4 | cut -d '/' -f 1 | bc | awk '{ print "Your credits: " $1 }')

echo $(solana validators | grep -A 999999999 Skip | grep -B 999999999 Skip | grep -v Skip | sed 's/(//g' | sed 's/)//g' | sed 's/  */ /g' | sed '/^#\|^$\| *#/d' | cut -d ' ' -f 10 | awk '{n += $1}; END{print n}') $(solana validators | grep -A 999999999 Skip | grep -B 999999999 Skip | grep -v Skip | sed 's/(//g' | sed 's/)//g' | sed 's/  */ /g' | sed '/^#\|^$\| *#/d' | cut -d ' ' -f 10 | wc -l | bc) | awk '{ print "Average cluster credits (minus grace 35%): " ($1/$2)*0.65 }' 

echo -e "${NOCOLOR}" && solana epoch-info | grep 'Epoch Completed' 
echo -e "${NOCOLOR}"

popd > /dev/null || exit 1