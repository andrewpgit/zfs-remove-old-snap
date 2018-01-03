#!/usr/bin/env bash

### Author Andrew;
### To clean old snapshot if zfs has capacity more 85%; 
### Last edited: Junery 02 2018;
###
### DELETE_SNAPSHOTS; MIN_SNAPSHOTS; ZPOOL_CAPACITY are variabels for Jenkins

COUNT_DELETE=${DELETE_SNAPSHOTS:=30}
COUNT_MIN=${MIN_SNAPSHOTS:=10}
ZFS_CAP=${ZPOOL_CAPACITY:=85}
ZFS=$(which zfs)
ZPOOL=$(which zpool)
ZPOOL_SIZE=$($ZPOOL list -H -o cap)
BASENAME=$(basename $0)
DATE=$(date +%F-%H.%M)
#Get list of snapshot
get_item_zfs() { 
	local list=''
	
	list=$($ZFS list -r -H -t snap -o name | $@)
	echo $list 

} 

#Show variables.
get_debug_var() {

	echo $COUNT_DELETE
	echo $ZFS_CAP
	echo $ZFS
	echo $ZPOOL
	echo $ZPOOL_SIZE
	echo $BASENAME
	echo $DATE
}

## Logs info
logs () {
	local DATE=$(date +%F-%T)
	local LOGFILE=/var/log/${BASENAME}.log
	
	printf "[%s]: %s \n" $DATE "$@" >> $LOGFILE
}

## To get zpool amount of capacity.
check_capacity_zpool() {
  	stat='OK'
  	local SIZE=$(echo $ZPOOL_SIZE | sed -r 's/(.*)%/\1/g')
	if [ $SIZE -ge $ZFS_CAP ]
		then
			stat='WARN'
	fi
	echo $stat
}

## To delete old zfs snapshot 
destroy_snap() {
	local COUNT=${1:-$COUNT_DELETE}
	local ARRAY_SNAP=(`get_item_zfs head -n ${COUNT}`)
	logs "The oldest $COUNT snapshots will been destroyed."
	for snapshot in "${ARRAY_SNAP[@]}"
		do 
		  $ZFS destroy $snapshot
		  sleep 0.5
	done
	logs "The Shapshots destroying have been completed."  

}


main() { 
logs "====================$DATE=================="

if ! [ -f $ZFS -a -f $ZPOOL ]; then
	logs "ERROR: Command $ZFS or $ZPOOL not found"
	exit 1
fi

result=$(check_capacity_zpool)
logs "The zpool capacity is $result"

if [ "$result" == "WARN" ]; then
	COUNT_SNAP=$(get_item_zfs wc -l)
	logs "The start to destroy snapshot"
	if [ $COUNT_SNAP -ge $COUNT_DELETE ]; then
		destroy_snap 
	elif [ $COUNT_SNAP -le $COUNT_DELETE ] && [ $COUNT_SNAP -ge $COUNT_MIN ]; then
		destroy_snap 10
	else 
		logs "Number of snapshots are too small. Snapshots will not destroy"	
	fi
fi

}

## Main function is run
main
logs "End destroy scritp"