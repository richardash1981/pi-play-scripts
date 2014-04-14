#!/bin/bash

# stop.sh
# script which manages a push button for stopping playing content on a pi
# when it is running headless

# load configuration settings (shared with the stop script)
source "/home/pi/buttonsets.sh"


# setup:
#	Program the GPIO correctly
###############################

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
  # set pull-down on stop input pin
  $gpio -g mode ${sbutton} down
  if [[ $? -ne 0 ]]; then
		  # failed to do input setup
		  echo "Failed to set mode of GPIO ${sbutton} with ${gpio}"
		  logger "Failed to set mode of GPIO ${sbutton} with ${gpio}"
		  exit 2
  fi

  # set power button as interupt on rising input
  $gpio edge ${sbutton} rising
  echo "Setup done"
}

#######################################################################
#	Function to wait for the stop button to be pressed
function waitStopButton
{
echo "Waiting for stop button press"
$gpio -g wfi ${sbutton} rising
if [[ $? -ne 0 ]] ; then
	# error waiting for button
	echo "Failed to wait for stop button"
	logger "Failed to wait for stop button"
else
	# attempt to stop anything (started by the playback script) which is
	# playing
	if [[ -f "${sndpidf}" ]] ; then
		# stop sound player
		kill $(cat "${sndpidf}")
	fi
	if [[ -f "${lightpidf}" ]] ; then
		# stop light player
		kill $(cat "${lightpidf}")
	fi
	# put system into a safe default state (the same as it was at start)
	setdefaultstate
fi

# wait a little before going back to start, to debounce the button
sleep 0.2s
}


#######################################################################
# The main program
#	Call our setup routing once, then wait for
#	the button to be pressed, which causes playback to be stopped.
#	Then go back to button watching.
#######################################################################

setup

while true; do
	# infinite loop
	waitStopButton
done


