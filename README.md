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

After cloning the repository and changing to its directory,
you can run the following commands:

```
sudo chmod 644 88-3DPrinter.rules
sudo chown root:root 88-3DPrinter.rules
sudo cp 88-3DPrinter.rules /etc/udev/rules.d
sudo udevadm control --reload-rules && sudo udevadm trigger
```
```
sudo chmod 755 ~/octoprint-pi/octoprint/logs/printerDetect
```