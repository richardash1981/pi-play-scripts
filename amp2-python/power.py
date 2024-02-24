#!/usr/bin/env python3
from gpiozero import Button, LED
from signal import pause
from subprocess import check_call

# Use the Local LED and button for power control

local_led = LED(35)

def on_press_local():
    print("Local pressed")
    # set LED off to provide feedback
    local_led.off()
    # shut system down
    check_call(['sudo', 'poweroff'])


# switch on LED on boot up
local_led.on()

# Button with 2-second debounce on it
local_button = Button(32, bounce_time=2)

local_button.when_pressed = on_press_local

pause()
