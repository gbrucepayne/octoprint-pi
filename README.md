# octoprint-pi

A configuration setup for running OctoPrint on Rasbperry Pi.
It enables powering on/off an ANYCUBIC 3D printer using GPIO control
via a relay module.
It also uses a Pi camera.

## GPIO Control

The chosen setup was to use GPIO #5 (pin 29) as a dedicated output control for
a simple relay module, driving the Normally Open contact to close the hot wire
of an AC power cord into the printer.
This will default to OFF when the Pi is switched on or loses power.

In order to preserve the state of the printer switch after an OctoPrint restart,
we use GPIO #6 (pin 31) connected to GPIO #5 configured as an input,
with pull-down to avoid turning on the printer accidentally.

The following settings in `/boot/config.txt` set the printer OFF
when the Pi powers up:
```
# 3D printer control
gpio=5=op,dl
gpio=6=ip,pd
```

## Prerequisites

You must have **git**, **docker** and **docker-compose** installed on the Pi.
```
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt update && sudo apt install -y git libffi-dev libssl-dev python3-dev
sudo pip install docker-compose
```

## Installation

1. Clone the repository and change into its directory:
    ```
    git clone https://github.com/gbrucepayne/octoprint-pi && cd octoprint-pi
    ```

2. Run the GPIO boot config script:
    ```
    sudo bash config.sh
    ```

3. Build the docker container:
    ```
    docker-compose up -d --build
    ```

4. Enable access to the **printerDetect** logs
    ```
    mkdir -p ~/octoprint-pi/docker/octoprint/logs/printerDetect
    sudo chmod 755 ~/octoprint-pi/docker/octoprint/logs/printerDetect
    ```

3. Setup permissions and copy `udev` host rules:
    ```
    sudo chmod 644 88-3DPrinter.rules
    sudo chown root:root 88-3DPrinter.rules
    sudo cp 88-3DPrinter.rules /etc/udev/rules.d
    sudo udevadm control --reload-rules && sudo udevadm trigger
    ```

## Restore from Backup

If you have a backup zip saved, you can import your prior settings.
Otherwise, proceed through step-by-step configuration.

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
    * **Restart Octoprint**
    `redirfd -w 2 /dev/null s6-svscanctl -t /var/run/s6/services`
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

## Configure the PSU Plugin

The `Dockerfile` should pre-install the **PSU Control** plugin that has been
modified to work with this project controlling the printer ON/OFF using a relay
connected to 2 GPIO ports on the Pi.

1. Click **Settings** and select **PLUGINS/PSU Control**:
    * **Switching** *Switching Method* `GPIO` with *On/Off GPIO Pin* `5`
    * **Sensing** *Sensing Method* `GPIO` with
    *Sensing GPIO Pin `6` as `Pull-Down`
    * **Power Off Options** check *Disconnect on power off*.
2. Click **Save**.
