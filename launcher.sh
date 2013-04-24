#!/bin/sh

#
# Copyright (c) 2013 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the MIT License
#

set -x

cd "$(dirname "$0")"

#
# determines the platform we are running on
#
[ $(hostname) = "kindle" ] && {
	PLATFORM="onKindle" 
} || {
	PLATFORM="onHost"
}

#
#
# @see http://stackoverflow.com/questions/392022/best-way-to-kill-all-child-processes
#
killtree () {

    local _pid=$1

    local _sig=${2-TERM}	#  default is SIGTERM

    kill -stop ${_pid}		#  needed to stop quickly forking parent from 
    						#+ producing child between child killing and 
    						#+ parent killing

    for _child in $(ps -o pid --no-headers --ppid ${_pid}); do

        killtree ${_child} ${_sig}

    done

    kill -${_sig} ${_pid}
}

#
#
#
launch_onHost () {

	./weather.sh &

	wpid=$(pgrep weather.sh)

	echo "Hit any key $wpid :"
	read x

	killtree "$wpid" "KILL"

}

#
#
#
launch_onKindle () {

	local activeInterface=`lipc-get-prop com.lab126.cmd activeInterface` # if not connected to wifi fail the test

#	/etc/init.d/powerd stop

	lipc-set-prop -i com.lab126.powerd preventScreenSaver 1

	killall -STOP cvm

	./weather.sh &

	wpid=$(pgrep weather.sh)

	waitforkey

	killtree "$wpid" "KILL"

	# reanimate the stopped processes
	killall -CONT cvm
#	/etc/init.d/powerd start
	
	if [ "$activeInterface" == "wifi" ]; then

		local cmState=`lipc-get-prop com.lab126.wifid cmState`

		if [ "$cmState" == "NA" ]; then	
			lipc-set-prop com.lab126.wifid enable 1
		fi	
		
	fi

	lipc-set-prop -i com.lab126.powerd preventScreenSaver 0

	# pressing the 'Home' button
	echo "send 101" > /proc/keypad

}

###############################################################################
# public functions
###############################################################################

launch_"$PLATFORM"

