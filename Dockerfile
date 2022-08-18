# reference supported arguments
ARG OCTOPRINT_BASE=octoprint/octoprint:latest
# Download base image
FROM $OCTOPRINT_BASE
# install from wheel - tbd install dev instead?
COPY plugins/ /octoprint/plugins
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt \
    && rm requirements.txt

# re-reference supported arguments and copy to environment vars
ARG OCTOPRINT_BASE
ENV OCTOPRINT_BASE=${OCTOPRINT_BASE}

# copy extra files to image
COPY mjpgStreamer.sh /etc/services.d/mjpg-streamer/run
COPY printerDetect.sh /usr/local/bin/printerDetect
