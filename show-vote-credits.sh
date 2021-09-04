#!/bin/bash
#Show Approximate Vote Credits

pushd `dirname ${0}` > /dev/null || exit 1

CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

EPOCH_INFO=`solana --url=localhost epoch-info`
SOLANA_VALIDATORS=`solana validators`
THIS_SOLANA_VALIDATOR_INFO=`solana validator-info get | awk '/$(solana address)/,/^$/'`
YOUR_VOTE_ACCOUNT=`echo -e "${SOLANA_VALIDATORS}" | grep $(solana address) | sed 's/  */ /g' | cut -d ' ' -f 3`
NODE_NAME=`$THIS_SOLANA_VALIDATOR_INFO | grep 'Name: ' | sed 's/Name//g' | tr -s ' '`
SOLANA_VERSION=`echo -e "${SOLANA_VALIDATORS}" | grep -A 999999999 Skip | grep -B 999999999 Skip | grep -v Skip | grep $(solana address) | sed 's/(/ /g'| sed 's/)/ /g' | tr -s ' ' | sed 's/ /\n/g' | grep -v % | grep -i -v [a-z⚠-] | egrep '\.+[[:digit:]]\.+[[:digit:]]+$' | awk '{print ($1)}'`

NODE_WITHDRAW_AUTHORITY=`solana vote-account ${YOUR_VOTE_ACCOUNT} | grep 'Withdraw Authority: ' | sed 's/Withdraw Authority: //g' | tr -s ' '`

TOTAL_ACTIVE_STAKE=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | awk '{n += $1}; END{print n}'`
TOTAL_ACTIVE_STAKE_COUNT=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | grep '' -c`

BOT_ACTIVE_STAKE=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep -B7 mvines | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | awk '{n += $1}; END{print n}'`
BOT_ACTIVE_STAKE_COUNT=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep -B7 mvines | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | grep '' -c`

SELF_ACTIVE_STAKE=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep -B7 'Withdraw Authority: ${NODE_WITHDRAW_AUTHORITY}' | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | awk '{n += $1}; END{print n}'`
SELF_ACTIVE_STAKE_COUNT=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep -B7 'Withdraw Authority: ${NODE_WITHDRAW_AUTHORITY}' | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | bc | grep '' -c`

OTHER_ACTIVE_STAKE=`echo "${TOTAL_ACTIVE_STAKE:-0} ${BOT_ACTIVE_STAKE:-0} ${SELF_ACTIVE_STAKE:-0}" | awk '{print $1 - $2 - $3}'`
OTHER_ACTIVE_STAKE_COUNT=`echo "${TOTAL_ACTIVE_STAKE_COUNT:-0} ${BOT_ACTIVE_STAKE_COUNT:-0} ${SELF_ACTIVE_STAKE_COUNT:-0}" | awk '{print $1 - $2 - $3}'`

ACTIVATING_STAKE=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep 'Activating Stake: ' | sed 's/Activating Stake: //g' | sed 's/ SOL//g' | awk '{n += $1}; END{print n}'`
DEACTIVATING_STAKE=`solana stakes ${YOUR_VOTE_ACCOUNT} | grep -B1 -i 'deactivates' | grep 'Active Stake' | sed 's/Active Stake: //g' | sed 's/ SOL//g' | awk '{n += $1}; END{print n}'`
NO_MOVING_STAKE=`echo "${TOTAL_ACTIVE_STAKE:-0} ${DEACTIVATING_STAKE:-0}" | awk '{print $1 - $2}'`

IDACC_BALANCE=`solana balance $(solana address)`
VOTEACC_BALANCE=`solana balance ${YOUR_VOTE_ACCOUNT}`

IS_DELINKED=`solana validators | grep ⚠️ | if (grep $(solana address) -c)>0; then echo -e "WARNING: ${RED}THIS NODE IS DELINKED\n\rconsider to check catchup, network connection and/or messages from your datacenter${NOCOLOR}"; else >/dev/null; fi`

YOUR_CREDITS=`solana vote-account ${YOUR_VOTE_ACCOUNT} | grep -A 4 History | grep -A 2 epoch | grep credits/slots | cut -d ' ' -f 4 | cut -d '/' -f 1 | bc`
ALL_CLUSTER_CREDITS_LIST=`solana validators | grep -A 999999999 Skip | grep -B 999999999 Skip | grep -v Skip | sed 's/(/ /g'| sed 's/)/ /g' | tr -s ' ' | sed 's/ /\n\r/g' | grep -v % | grep -i -v [a-z⚠️-] | egrep '^.{2,8}$' | grep -v -E '\.+[[:digit:]]\.+[[:digit:]]+$' | grep -v -E '^.{2,3}$'`
SUM_CLUSTER_CREDITS=`echo -e "${ALL_CLUSTER_CREDITS_LIST}" | awk '{n += $1}; END{print n}'`
COUNT_CLUSTER_VALIDATORS=`echo -e "${ALL_CLUSTER_CREDITS_LIST}" | wc -l | bc`
CLUSTER_CREDITS=`echo -e "$SUM_CLUSTER_CREDITS" "$COUNT_CLUSTER_VALIDATORS" | awk '{print ($1/$2)}' `


CLUSTER_SKIP=`echo -e "${SOLANA_VALIDATORS}" | grep 'Average Stake-Weighted Skip Rate' | sed 's/  */ /g' | cut -d ' ' -f 5 | cut -d '%' -f 1`

ALL_SLOTS=`solana leader-schedule | grep $(solana address) -c`
SKIPPED_COUNT=`solana -v block-production | grep $(solana address) | grep SKIPPED -c`
NON_SKIPPED_COUNT=`solana -v block-production | grep $(solana address) | grep SKIPPED -v -c | awk '{ if ($1 > 0) print $1-1; else print 0; fi}'`

SCHEDULE1=`solana --url=localhost leader-schedule | grep $(solana address) | tr -s ' ' | cut -d' ' -f2`
CURRENT_SLOT1=`echo -e "$EPOCH_INFO" | grep "Slot: " | cut -d ':' -f 2 | cut -d ' ' -f 2`
COMPLETED_SLOTS1=`echo -e "${SCHEDULE1}" | awk -v cs1="${CURRENT_SLOT1}" '{ if ($1 <= cs1) { print }}' | wc -l`
REMAINING_SLOTS1=`echo -e "${SCHEDULE1}" | awk -v cs1="${CURRENT_SLOT1}" '{ if ($1 > cs1) { print }}' | wc -l`

YOUR_SKIPRATE=`solana -v block-production | grep $(solana address) | sed -n -e 1p | sed 's/  */ /g' | sed '/^#\|^$\| *#/d' | cut -d ' ' -f 6 | cut -d '%' -f 1 | awk '{print $1}'`


TIME_NOW=`./see-schedule.sh | sed -n -e 1p`
NEAREST_SLOTS=`./see-schedule.sh | grep -m1 -A11 "new>" | sed -n -e 1p -e 5p -e 9p | sed 's/End: /End of epoch:/g' | sed 's/new> //g' | tr -s ' ' | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'`
LAST_BLOCK=`./see-schedule.sh | grep "old<" | tail -n1 | sed 's/old< //g' | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'`
LAST_BLOCK_STATUS=`solana -v block-production | grep $(solana address) | tail -n2 | tr -s ' ' | sed 's/ /\n\r/g' | sed '/^$/d' | grep -i 'skipped' -c | awk {'if ($1==0) print "DONE"; else print "SKIPPED"'}`
COLOR_LAST_BLOCK=`
    if [[ "${LAST_BLOCK_STATUS}" == "SKIPPED" ]];
	then
      echo "${RED}"
    else
      echo "${GREEN}"
    fi`


echo -e "${GREEN}"
echo -e "Time now: ${TIME_NOW:-''} ${NOCOLOR}" | awk 'length > 30'

echo -e "${CYAN}"
echo -e "Epoch Progress ${NOCOLOR}"

echo "$EPOCH_INFO" | grep 'Epoch: '
echo "$EPOCH_INFO" | grep 'Epoch Completed Percent'
echo "$EPOCH_INFO" | grep 'Epoch Completed Time'


echo -e "${CYAN}"
echo -e "This Node${NODE_NAME} ${NOCOLOR}"

echo -e "${IS_DELINKED}" | awk 'length > 5'

echo -e "Identity: $(solana address)"
echo -e "Identity Balance: ${IDACC_BALANCE}"
echo -e "VoteKey: ${YOUR_VOTE_ACCOUNT}"
echo -e "VoteKey Balance: ${VOTEACC_BALANCE}"
echo -e "Stake: Total(${TOTAL_ACTIVE_STAKE_COUNT:-0}) ${TOTAL_ACTIVE_STAKE:-0} SOL / From Bot(${BOT_ACTIVE_STAKE_COUNT:-0}) ${BOT_ACTIVE_STAKE:-0} SOL / Self-Stake(${SELF_ACTIVE_STAKE_COUNT:-0}) ${SELF_ACTIVE_STAKE:-0} SOL / Other(${OTHER_ACTIVE_STAKE_COUNT:-0}) ${OTHER_ACTIVE_STAKE} SOL"
echo -e "Stake Moving: no-moving ${NO_MOVING_STAKE:-0} SOL / activating  ${ACTIVATING_STAKE:-0} SOL / deactivating ${DEACTIVATING_STAKE:-0} SOL"
echo -e "Solana version: " | tr -d '\r\n' && echo -e "${SOLANA_VERSION}"

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

if (( $(bc<<<"scale=2;${YOUR_SKIPRATE:-0} <= ${CLUSTER_SKIP}+30"))); then
  echo -e "${GREEN}Your skiprate: ${YOUR_SKIPRATE:-0}% (Good) - Done: ${NON_SKIPPED_COUNT:-0}, Skipped: ${SKIPPED_COUNT:-0}${NOCOLOR}"
else
  echo -e "${RED}Your skiprate: ${YOUR_SKIPRATE:-0}% (Bad) - Done: ${NON_SKIPPED_COUNT:-0}, Skipped: ${SKIPPED_COUNT:-0}${NOCOLOR}"
fi

echo "Your Slots ${COMPLETED_SLOTS1}/${ALL_SLOTS} (${REMAINING_SLOTS1} remaining)"

echo -e "Your Min-Possible Skiprate is $(bc<<<"scale=2;${SKIPPED_COUNT:-0}*100/${ALL_SLOTS}")% (if all remaining slots will be done)${NOCOLOR}"
echo -e "Your Max-Possible Skiprate is $(bc<<<"scale=2;(${ALL_SLOTS}-${NON_SKIPPED_COUNT:-0})*100/${ALL_SLOTS}")% (if all remaining slots will be skipped)${NOCOLOR}"


echo -e "${CYAN}"
echo -e "Block Production ${NOCOLOR}"

if (( $(bc<<<"scale=2;${COMPLETED_SLOTS1} > 0"))); then
	echo -e "Last Block: ${COLOR_LAST_BLOCK}${LAST_BLOCK} ${LAST_BLOCK_STATUS}${NOCOLOR}"
else
	echo -e "This node did not produce any blocks yet"
fi

if (( $(bc<<<"scale=2;${REMAINING_SLOTS1} > 0"))); then
	echo -e "Nearest Slots (4 blocks each):"
	echo -e "${GREEN}${NEAREST_SLOTS}${NOCOLOR}"
else
	echo -e "This node will not have new blocks in this epoch"
fi

echo -e "${NOCOLOR}"

popd > /dev/null || exit 1