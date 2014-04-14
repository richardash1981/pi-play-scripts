# buttonsets.sh
# configuration file with settings for push button playback control

# our ready LED (BCM GPIO number)
ready=22

# The input button
button=23

# our play LED (BCM GPIO number)
play=4

# The input buttons
pbutton=24
sbutton=25

# the GPIO binary
gpio=/usr/local/bin/gpio

# lock file for playback
plkf="/tmp/plk.file"

# audio playback program and options. This should not produce lots of
# console output as there is no-where for it to usefully go
sndplayer="mplayer -vo null -nolirc -ao alsa -really-quiet"

# audio file to play back
soundtrack="/home/pi/gethsemene2.flac"

# file to record process ID of sound player in
sndpidf="/tmp/snd.pid"

# lightning file playback program
lightplayer="ola_recorder -u 0 -i 1 --syslog --playback"

# lighting file to play
lighttrack="/home/pi/gethsemene2v3.olar"

# lighting file to run to put the system into it's default (safe)
# state
lightdef="/home/pi/default.olar"

# file to record process ID of light player in
lightpidf="/tmp/light.pid"

##################################################################
# Initialise the system state after a manual stop or on system
# start.
function setdefaultstate {

# run default light setting (some safe static settings)
if [[ -f "${lightdef}" ]] ; then
	${lightplayer} "${lightdef}" &
fi
}

##################################################################
# function to check that our resources are in place
function checkres {
local resource
local error
error=0
for resource in "${soundtrack}" "${lighttrack}" "${lightdef}"
do
	# check it exists
	if [[ ! -f "${resource}" ]] ; then
		# doesn't exist
		error=1
		echo "Resource file ${resource} does not exist"
		logger "Resource file ${resource} does not exist"
	fi
done
# if a problem, flash light
if [[ ${error} -ne 0 ]] ; then
	# error with one or more files, 20 seocnd flashing light
	for i in $(seq 1 40)
	do
		# blink ready light
		$gpio -g write ${ready} 0
		sleep 0.25
		$gpio -g write ${ready} 1
		sleep 0.25
		# end in on state - system still booted up!
	done
fi
}

