# octoprint-pi

A configuration setup for running OctoPrint on Rasbperry Pi.
It enables powering on/off the 3D printer using GPIO control via a relay module.
It also uses a Pi camera.

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
docker-compose up -d --build
```
```
sudo chmod 644 88-3DPrinter.rules
sudo chown root:root 88-3DPrinter.rules
sudo cp 88-3DPrinter.rules /etc/udev/rules.d
sudo udevadm control --reload-rules && sudo udevadm trigger
```
```
sudo chmod 755 ~/octoprint-pi/octoprint/logs/printerDetect
```

## Configure the printer and camera

Login to the OctoPrint server on the LAN (e.g. http://raspberrypi).
Follow the setup wizard:
1. Access Control
2. Online connectivity check (e.g. 1440 minutes)
3. Anonymous usage tracking (enable)
4. Blacklist processing (enable)
5. Default printer profile
    1. **General**: `ANYCUBIC S3 Mega Pro`
    2. **Print bed**:
        * **Width (X)** 410
        * **Depth (Y)** 405
        * **Height (Z)** 453
6. Server Commands (TBC)
7. Webcam & timelapse
    * **Stream URL** `/webcam/?action=stream`
    * **Snapshot URL** `http://localhost:8080/?action=snapshot`
    * **Path to FFMPEG** `/usr/bin/ffmpeg`
8. Finish

### Setup the dynamic serial connection

1. Click the **Settings** menu bar item and select **PRINTER/Serial Connection**.
2. Under *General* tab, type in an Additional serial port: `/dev/ttyANYCUBIC`.
3. Click **Save**.

### Setup the camera

1. Open the **Settings** menu bar item and select **FEATURES/Webcam & Timelapse**.
2. Click *Test* for the stream URL and ensure the picture is correct.
3. If necessary, flip horizontally and/or vertically.
4. Click **Save**.

## Install the PSU Plugin

1. Click the **Settings** menu bar item and select **OCTOPRINT/Plugin Manager**.
2. Click *Get More*.
3. Search for `PSU` and select the one from Shawn Bruce, then **Install**.
4. Restart the container e.g. using SSH: `docker restart octoprint`
5. Reload the page and acknowledge any Wizard setup required.
6. Click **Settings** and select **PLUGINS/PSU Control**.