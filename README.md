# octoprint-pi

A configuration setup for running OctoPrint on Rasbperry Pi.
It enables powering on/off the 3D printer using GPIO control via a relay module.

## GPIO Control

The chosen setup was to use GPIO #4 (pin 7) as a dedicated output control for
a simple relay module driving the normally open contact to close the hot wire
of an AC power cord into the printer, which will default to OFF when the Pi is
switched on or loses power.

The following addition is made to `/boot/config.txt`:
```
# 3D printer control via GPIO#4
gpio=4=op,dl
```

## Dockerized OctoPrint

