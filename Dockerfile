# reference supported arguments
ARG OCTOPRINT_BASE=octoprint/octoprint:latest
# Download base image
FROM $OCTOPRINT_BASE

# re-reference supported arguments and copy to environment vars
ARG OCTOPRINT_BASE
ENV OCTOPRINT_BASE=${OCTOPRINT_BASE}

# install plugins
ENV PIP_USER false
RUN pip install \
    "https://github.com/gbrucepayne/OctoPrint-PSUControl/archive/dynamic-serial.zip"

# copy extra files to image
COPY mjpgStreamer.sh /etc/services.d/mjpg-streamer/run
COPY printerDetect.sh /usr/local/bin/printerDetect
