#!/usr/bin/with-contenv sh

if [ -n "$MJPEG_STREAMER_INPUT" ]; then
  echo "Deprecation warning: the environment variable '\$MJPEG_STREAMER_INPUT' was renamed to '\$MJPG_STREAMER_INPUT'"

  MJPG_STREAMER_INPUT=$MJPEG_STREAMER_INPUT
fi

if ! expr "$MJPG_STREAMER_INPUT" : ".*\.so.*" >/dev/null; then
  MJPG_STREAMER_INPUT="input_uvc.so $MJPG_STREAMER_INPUT"
fi

# only exec the streamer if the (internal) camera device exists
if [ -e "$CAMERA_DEV" ]; then
  exec mjpg_streamer \
    -i "/usr/local/lib/mjpg-streamer/$MJPG_STREAMER_INPUT -d $CAMERA_DEV" \
    -o "/usr/local/lib/mjpg-streamer/output_http.so -w /usr/local/share/mjpg-streamer/www -p 8080"
fi

# arriving here means camera device not linked yet - take the service down
s6-svc -d /var/run/s6/services/mjpg-streamer
