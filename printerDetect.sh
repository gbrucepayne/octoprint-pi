#!/usr/bin/with-contenv bash
# Script is intended to be run within a Docker container (s6 service)

# support script re-naming
SCRIPT=$(basename "$0")

log() {
  # being run interactively?
  if [ "$(tty)" = "not a tty" ]; then
    # no! use s6 logging
    echo "$1" | s6-log T n20 s50000 "/octoprint/octoprint/logs/${SCRIPT}"
  else
    # yes! fake it
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$$ - ${SCRIPT} - $1"
  fi
}

# decode arguments
case "$#" in
  2)
    EXT_CAMERA_DEV=/host/dev/$(basename "$2")
    INT_CAMERA_DEV="$CAMERA_DEV"
    ;&
  1)
    EXT_PRINTER_DEV=/host/dev/$(basename "$1")
    INT_PRINTER_DEV=/dev/$(basename "$1")
    ;;
  *)
    log "Usage: ${SCRIPT} printer {camera}"
    exit -1
    ;;
esac

# assumptions
RESTART_OCTOPRINT=false
SHOULD_ENABLE_CAMERA=false

# does the external printer device exist?
if [ -e "$EXT_PRINTER_DEV" ]; then
  # yes! that means the camera should be on
  SHOULD_ENABLE_CAMERA=true
  # discover the external device attributes
  EXT_MAJOR=$((16#$(stat -L -c "%t" "$EXT_PRINTER_DEV")))
  EXT_MINOR=$((16#$(stat -L -c "%T" "$EXT_PRINTER_DEV")))
  # does the internal printer device exist?
  if [ -e "$INT_PRINTER_DEV" ]; then
    # yes! discover its device attributes
    INT_MAJOR=$((16#$(stat -L -c "%t" "$EXT_PRINTER_DEV")))
    INT_MINOR=$((16#$(stat -L -c "%T" "$EXT_PRINTER_DEV")))
    # both exist - do they match?
    if [ "$EXT_MAJOR" = "$INT_MAJOR" -a "$EXT_MINOR" = "$INT_MINOR" ]; then
      # yes! no need to do anything
      log "$INT_PRINTER_DEV already linked"
    else
      # no! mismatch - must re-link
      log "re-linking $INT_PRINTER_DEV"
      # unlink old
      unlink "$INT_PRINTER_DEV"
      # link new
      mknod "$INT_PRINTER_DEV" c "$EXT_MAJOR" "$EXT_MINOR"
      # remember to restart OctoPrint
      RESTART_OCTOPRINT=true
    fi
  else
    # no! simply link internal to external
    log "linking $INT_PRINTER_DEV"
    # link it
    mknod "$INT_PRINTER_DEV" c "$EXT_MAJOR" "$EXT_MINOR"
    # remember to restart OctoPrint
    RESTART_OCTOPRINT=true
  fi
else
  # no! passed a non-existent external printer device
  log "$EXT_PRINTER_DEV does not exist"
  # does an internal printer device exist?
  if [ -e "$INT_PRINTER_DEV" ]; then
    # yes! internal is now redundant
    log "unlinking $INT_PRINTER_DEV"
    # unlink it
    unlink "$INT_PRINTER_DEV"
    # remember to restart OctoPrint
    RESTART_OCTOPRINT=true
  fi
fi

# is the container set up to run the streamer?
if $ENABLE_MJPG_STREAMER; then
  # yes! should the streamer be active?
  if $SHOULD_ENABLE_CAMERA; then
    # does the external camera device exist?
    if [ -e "$EXT_CAMERA_DEV" ]; then
      # yes! discover its device attributes
      EXT_MAJOR=$((16#$(stat -L -c "%t" "$EXT_CAMERA_DEV")))
      EXT_MINOR=$((16#$(stat -L -c "%T" "$EXT_CAMERA_DEV")))
      # does the internal camera device exist?
      if [ -e "$INT_CAMERA_DEV" ]; then
        # yes! discover its device attributes
        INT_MAJOR=$((16#$(stat -L -c "%t" "$INT_CAMERA_DEV")))
        INT_MINOR=$((16#$(stat -L -c "%T" "$INT_CAMERA_DEV")))
        # both exist - do they match?
        if [ "$EXT_MAJOR" = "$INT_MAJOR" -a "$EXT_MINOR" = "$INT_MINOR" ]; then
          # yes! no need to do anything
          log "$INT_CAMERA_DEV already linked"
        else
          # no! mismatch - must re-link
          log "re-linking $INT_CAMERA_DEV"
          # unlink old
          unlink "$INT_CAMERA_DEV"
          # link new
          mknod "$INT_CAMERA_DEV" c "$EXT_MAJOR" "$EXT_MINOR"
          # restart the streaming service
          s6-svc -r /var/run/s6/services/mjpg-streamer
        fi
      else
        # no! simply link internal to external
        log "linking $INT_CAMERA_DEV"
        # link it
        mknod "$INT_CAMERA_DEV" c "$EXT_MAJOR" "$EXT_MINOR"
        # bring up the streaming service
        s6-svc -u /var/run/s6/services/mjpg-streamer
      fi
    else
      # no! passed a null or non-existent external camera device
      log "$EXT_CAMERA_DEV does not exist"
      # does the internal camera device exist?
      if [ -e "$INT_CAMERA_DEV" ]; then
        # yes! internal is now redundant
        log "unlinking $INT_CAMERA_DEV"
        # unlink it
        unlink "$INT_CAMERA_DEV"
        # stop the streaming service
        s6-svc -d /var/run/s6/services/mjpg-streamer
      fi
    fi
  else
    # no! camera not required
    log "No camera service configured"
    # is the internal camera device defined?
    if [ -e "$INT_CAMERA_DEV" ]; then
      # yes! internal is now redundant
      log "disabling $INT_CAMERA_DEV"
      # unlink it
      unlink "$INT_CAMERA_DEV"
      # stop the streaming service
      s6-svc -d /var/run/s6/services/mjpg-streamer
    fi
  fi
else
  log "ENABLE_MJPG_STREAMER disabled in docker-compose.yml"
fi

# should OctoPrint be restarted ?
if $RESTART_OCTOPRINT; then
  log "Restarting OctoPrint service"
  s6-svc -r /var/run/s6/services/octoprint
fi
