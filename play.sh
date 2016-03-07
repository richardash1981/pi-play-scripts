#!/bin/bash

# play.sh
# script which manages a push button and LED for playing content on a pi
# when it is running headless

# load configuration settings (shared with the stop script)
source "/home/pi/pi-play-scripts/buttonsets.sh"


# setup:
#	Program the GPIO correctly and initialise the playback light
#######################################################################

setup ()
{
  echo Setup
  # test that the gpio command is available
  if [[ ! -e ${gpio} ]] ; then
		  # cannot execute
		  echo "Cannot execute gpio program at ${gpio}"
		  logger "Cannot execute gpio program at ${gpio}"
		  exit 1
  fi
  # set LED pin as an output
  $gpio -g mode ${play} out
  if [[ $? -ne 0 ]]; then
		  # failed to do output
		  echo "Failed to set mode of GPIO ${play} with ${gpio}"
		  logger "Failed to set mode of GPIO ${play} with ${gpio}"
		  exit 2
  fi
  # force it off
  $gpio -g write ${play} 0
  # set pull-down on input pin
  $gpio -g mode ${pbutton} down
  # set play button as interupt on rising input
  $gpio edge ${pbutton} rising
  echo "Setup done"
}


#######################################################################
#	Function to wait for the play button to be pressed
function waitButton
{
echo "Waiting for play button press"
$gpio -g wfi ${pbutton} rising
if [[ $? -ne 0 ]] ; then
	# error waiting for button
	echo "Failed to wait for playback button"
	logger "Failed to wait for playback button"
else
	# check for spurious trigger (debounce it)
	sleep 0.1
	# read state
	state=$(${gpio} -g read ${pbutton})
	echo "Playback pin state is ${state}"

	if [[ ${state} -eq 1 ]] ; then
		# still pressed
		running=0
	else
		#transient trigger
		echo "transient trigger"
		return;
		# this goes back to the outermost infinite loop, which promptly
		# re-calls this function, so back to waiting.
	fi

	# see if we should actually start playback - try and lock the lock file

	# this line will only write our PID to the file if it isn't there
	if ( set -o noclobber; echo "$$" > "${plkf}") 2> /dev/null; then
		# lock sucessful. Set up an exit trap to remove lock if we die
		trap 'rm -f "${plkf}"; exit $?' INT TERM EXIT
		# can now do something protected by the lock
		# not playing, start playback
		doplayback

		# end of playback, release lock
		rm -f "${plkf}"
		# disable exit trap again
		trap - INT TERM EXIT
	else
		# already playing, show lock file details for debugging
		echo "already playing, not playing again"
		echo "lock created by process $(cat ${plkf})"
		ls -l "${plkf}"
	fi
fi
}

#######################################################################
#	Function to do light and sound playback
function doplayback
{
	echo "starting playback"
	logger "Starting playback on button press"
	# calls to this function are locked, so we will never be multiply called
	# and not not have to worry about clobbering ourselves
	# LED on
	$gpio -g write ${play} 1

	# sound playback is slower to start, launch it first
	if [[ -f "${soundtrack}" ]] ; then
		${sndplayer} "${soundtrack}" &
		local sndpid="$!"
	fi
	if [[ -f "${lighttrack}" ]] ; then
		${lightplayer} "${lighttrack}" &
		local lightpid="$!"
	fi

	# save PIDs to files, the stop script needs them
	echo "${sndpid}" > "${sndpidf}"
	echo "${lightpid}" > "${lightpidf}" 
	
	# this could take a long time, wait for _both_ process to complete
	wait ${sndpid} ${lightpid}
	echo "end of playback"
	logger "End of playback"
	# remove pid files, be tidy
	\rm -f "${sndpidf}" "${lightpidf}"
	# LED off
	$gpio -g write ${play} 0
}


#######################################################################
# The main program
#	Call our setup routing once, then wait for
#	the button to be pressed, which causes playback. Then do playback, 
# and go back to button watching.
#######################################################################

setup

setdefaultstate

while true; do
	# infinite loop
	waitButton
done


