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
    "https://github.com/kantlivelong/OctoPrint-PSUControl/archive/master.zip"

# copy extra files to image
COPY mjpgStreamer.sh /etc/services.d/mjpg-streamer/run
COPY printerDetect.sh /usr/local/bin/printerDetect
COPY custom_psucontrol/__init__.py /octoprint/plugins/lib/python3.8/site-packages/octoprint_psucontrol
