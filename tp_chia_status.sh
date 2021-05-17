#!/bin/bash
cd /home/$(whoami)/chia-blockchain/ && . ./activate

while getopts 'u:p:r:' flag; do
	case "${flag}" in
		u) user="${OPTARG}" ;;
		p) pw="${OPTARG}" ;;
		r) host="${OPTARG}" ;;
		*) echo "Usage: chia_status.sh [ -u USERNAME ] [ -p PASSWORD ] [ -r HOSTNAME ]"
			exit 1 ;;
	esac
done

if [ "$user" = "" ] || [ "$pw" = "" ] || [ "$host" = "" ]; then
	echo "Missing username, password, or host"
	exit 1
fi

ver="$(chia version)"
info="$(chia wallet show)"
farmSum="$(chia farm summary)"
walletAddress="$(chia wallet get_address)"
chiaState="$(chia show -s)"
connections="$(chia show -c)"
walletSyncStatus=$(printf "$info" | grep  "Sync status:" | grep -oP ": \K.*")
walletHeight=$(printf "$info" | grep "Wallet height:" | grep -oP ": \K.*")
totalBalance=$(printf "$info" | grep "\-Total Balance:" | grep -o "[0-9]*\.[0-9]* xch")
pendingTotalBalance=$(printf "$info" | grep "\-Pending Total Balance:" | grep -o "[0-9]*\.[0-9]* xch")
spendable=$(printf "$info" | grep "\-Spendable:" | grep -o "[0-9]*\.[0-9]* xch")

json=$( jq -n \
	--arg wss "$walletSyncStatus" \
	--arg wa "$walletAddress" \
	--arg wh "$walletHeight" \
	--arg tb "$totalBalance" \
	--arg ptb "$pendingTotalBalance" \
	--arg sp "$spendable" \
	--arg v "$ver" \
	--arg fs "$farmSum" \
	--arg cs "$chiaState" \
	--arg con "$connections" \
	'{walletSyncStatus: $wss, walletAddress: $wa, walletHeight: $wh, totalBalance: $tb, pendingTotalBalance: $ptb, spendable: $sp, chiaVersion: $v, farmSummary: $fs, chiaState: $cs, connections: $con}' )


printf "$json"

curl "$host" \
	--request POST \
	--header "Accept:application/json" \
	--header "Content-Type:application/json" \
	--data "$json" \
	--user "$user":"$pw"

exit
