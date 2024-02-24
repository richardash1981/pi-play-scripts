#!/bin/bash

# shutdown.sh
# script which manages a push button and LED for shutting down a pi
# when it is running headless

# script configuration file
source "/home/pi/pi-play-scripts/buttonsets.sh"

# setup:
#	Program the GPIO correctly and initialise the ready light
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
  $gpio -g mode ${ready} out
  if [[ $? -ne 0 ]]; then
		  # failed to do output
		  echo "Failed to set mode of GPIO ${ready} with ${gpio}"
		  logger "Failed to set mode of GPIO ${ready} with ${gpio}"
		  exit 2
  fi
  # to be visible, force it off first
  $gpio -g write ${ready} 0
  # wait a little
  sleep 1
  # turn it on
  $gpio -g write ${ready} 1
  # set pull-down on input pin
  $gpio -g mode ${button} down
  # set power button as interupt on rising input
  $gpio edge $button rising

  # set Mains pin as an output
  $gpio -g mode ${mainsout} out
  if [[ $? -ne 0 ]]; then
		  # failed to do output
		  echo "Failed to set mode of GPIO ${mainsout} with ${gpio}"
		  logger "Failed to set mode of GPIO ${mainsout} with ${gpio}"
		  exit 2
  fi
  # turn it on
  $gpio -g write ${mainsout} 1
 

  echo "Setup done"
}

# waitButton:
#	Function to wait for the power button to be pressed
#######################################################################
function waitButton
{
echo "Waiting for button press"
#$gpio -g wfi ${button} rising

# will change to zero when genuine shutdown comes along
local running=1

while [[ $running -eq 1 ]] ;
do
	# test the button for pressing

	$gpio -g wfi ${button} falling
	if [[ $? -ne 0 ]] ; then
		# error waiting for button
		echo "Failed to wait for shutdown button"
		logger "Failed to wait for shutdown button"
		# give up
		exit
	else
		echo "Button press edge"
	
		# debounce the button press. Only proceed if the button is pressed for
		# more than 0.1 seconds
		sleep 0.1
		# read state
		state=$(${gpio} -g read ${button})
		echo "Shutdown pin state is ${state}"

		if [[ ${state} -eq 0 ]] ; then
			# still pressed
			running=0
		else
			#transient trigger
			echo "transient trigger"
		fi
	fi
	# go back to the start of the script, to wait again
done

# if we get here, then in a genuine shutdown cycle
echo "shutdown! shutdown! shutdown!"
# switch the aux mains out off
$gpio -g write ${mainsout} 0
shutdown -h now

}

#######################################################################
# The main program
#	Check that the resources we need are in place
#	Call our setup routine once, then wait for
#	the button to be pressed, which causes a shutdown. This will
#   then cause the script to be stopped
#######################################################################

setup

checkres

waitButton


