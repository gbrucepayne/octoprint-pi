# reference supported arguments
ARG OCTOPRINT_BASE=octoprint/octoprint:latest
# Download base image
FROM $OCTOPRINT_BASE
COPY custom_psucontrol /opt/custom_psucontrol
RUN pip install --upgrade pip \
    && pip install --no-index --find-links=/opt/custom_psucontrol/ octoprint_psucontrol

# re-reference supported arguments and copy to environment vars
ARG OCTOPRINT_BASE
ENV OCTOPRINT_BASE=${OCTOPRINT_BASE}

# copy extra files to image
COPY mjpgStreamer.sh /etc/services.d/mjpg-streamer/run
COPY printerDetect.sh /usr/local/bin/printerDetect
