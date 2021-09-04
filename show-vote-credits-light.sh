#!/bin/bash
#Show Approximate Vote Credits

pushd `dirname ${0}` > /dev/null || exit 1

CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

EPOCH_INFO=`solana --url=localhost epoch-info`
SCHEDULE=`solana --url=localhost leader-schedule | grep $(solana address)`
SOLANA_VALIDATORS=`solana validators`
YOUR_VOTE_ACCOUNT=`echo -e "${SOLANA_VALIDATORS}" | grep $(solana address) | sed 's/  */ /g' | cut -d ' ' -f 3`

YOUR_CREDITS=`solana vote-account ${YOUR_VOTE_ACCOUNT} | grep -A 4 History | grep -A 2 epoch | grep credits/slots | cut -d ' ' -f 4 | cut -d '/' -f 1 | bc`
ALL_CLUSTER_CREDITS_LIST=`echo -e "${SOLANA_VALIDATORS}" | grep -A 999999999 Skip | grep -B 999999999 Skip | grep -v Skip | sed 's/(//g' | sed 's/)//g' | sed 's/  */ /g' | sed '/^#\|^$\| *#/d' | cut -d ' ' -f 10`
SUM_CLUSTER_CREDITS=`echo -e "${ALL_CLUSTER_CREDITS_LIST}" | awk '{n += $1}; END{print n}'`
COUNT_CLUSTER_VALIDATORS=`echo -e "${ALL_CLUSTER_CREDITS_LIST}" | wc -l | bc`
CLUSTER_CREDITS=`echo -e "$SUM_CLUSTER_CREDITS" "$COUNT_CLUSTER_VALIDATORS" | awk '{print ($1/$2)}' `


CLUSTER_SKIP=`echo -e "${SOLANA_VALIDATORS}" | grep 'Average Unw' | sed 's/  */ /g' | cut -d ' ' -f 5 | cut -d '%' -f 1`

ALL_SLOTS=`solana leader-schedule | grep $(solana address) -c`
SKIPPED_COUNT=`solana -v block-production | grep $(solana address) | grep SKIPPED -c`
NON_SKIPPED_COUNT=`solana -v block-production | grep $(solana address) | grep SKIPPED -v -c | awk '{print $1-1}'`

CURRENT_SLOT=`echo -e "$EPOCH_INFO" | grep "Slot: " | cut -d ':' -f 2 | cut -d ' ' -f 2`
COMPLETED_SLOTS=`echo -e "${SCHEDULE}" | awk -v cs="${CURRENT_SLOT}" '{ if ($1 <= cs) { print }}' | wc -l`
REMAINING_SLOTS=`echo -e "${SCHEDULE}" | awk -v cs="${CURRENT_SLOT}" '{ if ($1 > cs) { print }}' | wc -l`

YOUR_SKIPRATE=`solana -v block-production | grep $(solana address) | sed -n -e 1p | sed 's/  */ /g' | sed '/^#\|^$\| *#/d' | cut -d ' ' -f 6 | cut -d '%' -f 1 | awk '{print $1}'`


echo -e "${CYAN}"
echo -e "Epoch Progress ${NOCOLOR}"

echo "$EPOCH_INFO" | grep 'Epoch: '
echo "$EPOCH_INFO" | grep 'Epoch Completed Percent'
echo "$EPOCH_INFO" | grep 'Epoch Completed Time'

echo -e "${CYAN}"
echo -e "Vote-Credits ${NOCOLOR}"

echo -e "Average cluster credits: ${CLUSTER_CREDITS} (minus grace 35%: $(bc<<<"scale=2;${CLUSTER_CREDITS}*0.65"))"

if (( $(bc<<<"scale=0;${YOUR_CREDITS} >= ${CLUSTER_CREDITS}*0.65"))); then
  echo -e "${GREEN}Your credits: ${YOUR_CREDITS} (Good)${NOCOLOR}"
else
  echo -e "${RED}Your credits: ${YOUR_CREDITS} (Bad)${NOCOLOR}"
fi


echo -e "${CYAN}"
echo -e "Skip Rate ${NOCOLOR}"

echo -e "Average cluster skiprate: ${CLUSTER_SKIP}% (plus grace 30%: $(bc<<<"scale=2;${CLUSTER_SKIP}+30")%)"

if (( $(bc<<<"scale=2;${YOUR_SKIPRATE} <= ${CLUSTER_SKIP}+30"))); then
  echo -e "${GREEN}Your skiprate: ${YOUR_SKIPRATE}% (Good) - Done: ${NON_SKIPPED_COUNT}, Skipped: ${SKIPPED_COUNT}${NOCOLOR}"
else
  echo -e "${RED}Your skiprate: ${YOUR_SKIPRATE}% (Bad) - Done: ${NON_SKIPPED_COUNT}, Skipped: ${SKIPPED_COUNT}${NOCOLOR}"
fi

echo "Your Slots ${COMPLETED_SLOTS}/${ALL_SLOTS} (${REMAINING_SLOTS} remaining)"

echo -e "Your Min-Possible Skiprate is $(bc<<<"scale=2;${SKIPPED_COUNT}*100/${ALL_SLOTS}")% (if all remaining slots will be done)${NOCOLOR}"
echo -e "Your Max-Possible Skiprate is $(bc<<<"scale=2;(${ALL_SLOTS}-${NON_SKIPPED_COUNT})*100/${ALL_SLOTS}")% (if all remaining slots will be skipped)${NOCOLOR}"


echo -e "${NOCOLOR}"

popd > /dev/null || exit 1