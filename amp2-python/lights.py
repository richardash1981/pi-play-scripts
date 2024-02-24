#!/usr/bin/env python3

# DMX lights control script for AMP2 / OLA

import gpiozero
from signal import pause
import subprocess
import sys

def main(argv):
    """Main function run when script is started.

    Parameters
    ----------
    argv : list
        List of command line arguments to the program.
    """
    # Set up hardware
    Setup()

    # Create button/LED handler object
    controller = ButtonLightController()

    # Load starting scene
    RunScene("startup.olar")

    # Pause script until events come along and are handled.
    pause()


def Setup():
    """Set up the hardware.

    Put GPIO pin into correct state to turn on the RS-485 line driver (which seems to come on
    anyway via a pull-up, but better explictly on until I work out how to do this in the device
    tree).
    """
    # Make GPIO pin 17 an output and set it high
    dir_control = gpiozero.DigitalOutputDevice(17, initial_value=True)

class ButtonLightController():
    """Class which controls lights when buttons are pressed.
    """

    def __init__(self):
        """Initialiser method sets up the I/O pins.
        """
        # Set buttons and attach their handlers
        self.ok_button = gpiozero.Button(34, pull_up=True, bounce_time=0.2)
        self.ok_button.when_pressed = self.OnPressOk
        self.f1_button = gpiozero.Button(33, pull_up=True, bounce_time=0.2)
        self.f1_button.when_pressed = self.OnPressF1
        # Set up LED next to OK button, turn it off (lights start off)
        self.ok_led = gpiozero.LED(36, initial_value=False)

    def OnPressOk(self):
        """Handler function called when the "OK" button is pressed. Turns lights on.
        """
        print("OK pressed")
        if not self.ok_led.is_lit:
            # lights are not on
            self.ok_led.on()
            RunScene("on.olar")

    def OnPressF1(self):
        """Handler function called when the "F1" button is pressed. Turns lights off.
        """
        print("F1 pressed")
        if self.ok_led.is_lit:
            # lights are on
            self.ok_led.off()
            RunScene("off.olar")

def RunScene(filename: str):
    """Run the ola_recorder command line to play a lightning scene file into the system.

    Parameters
    ----------
    filename :
        File to be played.
    """
    try:
        subprocess.check_call(['ola_recorder', '--iterations', '1', '--playback', filename])
        print("Command completed")
    except subprocess.CalledProcessError as err:
        print("Process failed with exit status %s", err.returncode)

# Execute main function on entrance.
if __name__ == '__main__':
    sys.exit(main(sys.argv))
