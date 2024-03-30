#!/usr/bin/env python3

# AMP2 LED flasher script

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
    # Setup()
    # Create LED handler object
    controller = CommsBlinker()

    controller.Set([0.01, 1.0, 0.1])

    controller.Pulse(4.0)

    time.sleep(10)


    controller.Pulse(1.0)


    # Pause script until events come along and are handled.
    pause()


class CommsBlinker():
    """Class which controls the three COMMS LEDs.
    """

    def __init__(self):
        """Initialiser method sets up the I/O pins.
        """
        # Set up COMMS LEDboard
        self.ledboard = gpiozero.LEDBoard(39, 38, 37, pwm=True)
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
        phase_time = time_sec / 3.0
        power = 2.5
        
        led1_thread = LedThread(self.ledboard[0],fade_in_time=time_change, fade_out_time=time_change, power=power)
        led1_thread.start()

        time.sleep(phase_time)
 
        led2_thread = LedThread(self.ledboard[1],fade_in_time=time_change, fade_out_time=time_change, power=power)
        led2_thread.start()
       
        time.sleep(phase_time)
        #self.ledboard[2].pulse(fade_in_time=time_change, fade_out_time=time_change)
        led3_thread = LedThread(self.ledboard[2],fade_in_time=time_change, fade_out_time=time_change, power=power)
        led3_thread.start()

        self.led_threads = [led1_thread, led2_thread, led3_thread]


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
            print(f"Fade in {steps_in} steps")
            for step_in in range(0, steps_in):
                bright = pow(step_in / steps_in, self.power)
                self.led.value = bright
                time.sleep(interval)
                if self.stop:
                    break
            print(f"Fade out {steps_out}")
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
