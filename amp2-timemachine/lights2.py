#!/usr/bin/env python3

# DMX lights control script for AMP2 / OLA

import gpiozero
from signal import pause
import subprocess
import sys
import threading
import time

def main(argv):
    """Main function run when script is started.

    Parameters
    ----------
    argv : list
        List of command line arguments to the program.
    """
    # Set up hardware
    Setup()

    # Create COMMS LED handler object
    led_controller = CommsBlinker()
    # Create button/LED handler object
    controller = ButtonLightController(led_controller)

    # Set LEDs pulsing slowly
    led_controller.Pulse(4.0)

    # Give time for OLAD to be ready
    time.sleep(2)
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

    def __init__(self, led_controller):
        """Initialiser method sets up the I/O pins.
        """
        self.led_controller = led_controller
        # Set buttons and attach their handlers
        self.ok_button = gpiozero.Button(34, pull_up=True, bounce_time=0.2)
        self.ok_button.when_pressed = self.OnPressOk
        self.f1_button = gpiozero.Button(33, pull_up=True, bounce_time=0.2)
        self.f1_button.when_pressed = self.OnPressF1

    def OnPressOk(self):
        """Handler function called when the "OK" button is pressed.
        """
        print("OK pressed")
        self.led_controller.Pulse(1.0)
        RunScene("OK.olar")
        self.led_controller.Pulse(4.0)

    def OnPressF1(self):
        """Handler function called when the "F1" button is pressed. Turns lights off.
        """
        print("F1 pressed")
        self.led_controller.Pulse(1.0)
        RunScene("F1.olar")
        self.led_controller.Pulse(4.0)

def RunScene(filename: str):
    """Run the ola_recorder command line to play a lightning scene file into the system.

    Parameters
    ----------
    filename :
        File to be played.
    """
    try:
        print("About to run command")
        subprocess.check_call(['ola_recorder', '--iterations', '1', '--playback', filename])
        print("Command completed")
    except subprocess.CalledProcessError as err:
        print("Process failed with exit status %s", err.returncode)


class CommsBlinker():
    """Class which controls the three COMMS LEDs.
    """

    def __init__(self):
        """Initialiser method sets up the I/O pins.
        """
        # Set up COMMS LEDboard
        self.ledboard = gpiozero.LEDBoard(39, 38, 37, 36, pwm=True)
        self.led_threads = None

    def On(self, led: int):
        """Switch an LED full on.
        """
        self.leds[led - 1].value = 1.0

    def Set(self, bright):
        """Switch an LED to a set brightness
        """
        self.ledboard.value = bright

    def Pulse(self, time_sec):

        # stop LED existing pulses
        if self.led_threads is not None:
            for led in self.led_threads:
                led.stop = True

        time_change = time_sec / 2.0
        phase_time = time_sec / len(self.ledboard)
        power = 2.5
        
        self.led_threads = []
        for led in self.ledboard:

            led_thread = LedThread(led,fade_in_time=time_change, fade_out_time=time_change, power=power)
            led_thread.start()
            self.led_threads.append(led_thread)
            time.sleep(phase_time)


class LedThread(threading.Thread):
    """Class to puse one LED using a log pulse.
    """
    def __init__(self, led, fade_in_time = 1.0, fade_out_time = 1.0, power=2):
        threading.Thread.__init__(self)
        self.led = led
        self.fade_in_time = fade_in_time
        self.fade_out_time = fade_out_time
        self.power = power
        self.stop = False

    def run(self):
        """Overload for thread class interface.
        """
        self.Pulse()
    

    def Pulse(self):
        interval = 0.02
        steps_in = int(self.fade_in_time / interval)
        steps_out = int(self.fade_out_time / interval)
        while True:
            for step_in in range(0, steps_in):
                bright = pow(step_in / steps_in, self.power)
                self.led.value = bright
                time.sleep(interval)
                if self.stop:
                    break
            for step_out in range(0, steps_out):
                bright = pow(1.0 - (step_out / steps_out), self.power)
                self.led.value = bright
                time.sleep(interval)
                if self.stop:
                    break

            if self.stop:
                break

        # fell out of loop and exit
        self.stop = False

# Execute main function on entrance.
if __name__ == '__main__':
    sys.exit(main(sys.argv))
