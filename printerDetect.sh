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
    # CAMERA_DEV is an optional container environment variable
    INT_CAMERA_DEV="${CAMERA_DEV}"
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
if [ -e "${EXT_PRINTER_DEV}" ]; then
  SHOULD_ENABLE_CAMERA=true
  # discover the external device attributes
  EXT_MAJOR=$((16#$(stat -L -c "%t" "${EXT_PRINTER_DEV}")))
  EXT_MINOR=$((16#$(stat -L -c "%T" "${EXT_PRINTER_DEV}")))
  log "Found host printer ${EXT_PRINTER_DEV} (${EXT_MAJOR},${EXT_MINOR})"
  # does the container printer device exist?
  if [ -e "${INT_PRINTER_DEV}" ]; then
    # discover container device attributes
    INT_MAJOR=$((16#$(stat -L -c "%t" "${INT_PRINTER_DEV}")))
    INT_MINOR=$((16#$(stat -L -c "%T" "${INT_PRINTER_DEV}")))
    # both exist - do they match?
    if [ "${EXT_MAJOR}" = "${INT_MAJOR}" -a "${EXT_MINOR}" = "${INT_MINOR}" ]; then
      log "Host and container printers linked"
    else
      log "WARNING: Re-linking printer ${INT_PRINTER_DEV}"
      unlink "${INT_PRINTER_DEV}"
      mknod "${INT_PRINTER_DEV}" c "${EXT_MAJOR}" "${EXT_MINOR}"
      RESTART_OCTOPRINT=true
    fi
  else
    log "Linking container printer ${INT_PRINTER_DEV} to host (${EXT_MAJOR},${EXT_MINOR})"
    mknod "${INT_PRINTER_DEV}" c "${EXT_MAJOR}" "${EXT_MINOR}"
    RESTART_OCTOPRINT=true
  fi
else
  log "WARNING: Host printer ${EXT_PRINTER_DEV} does not exist - assume powered down"
  if [ -e "${INT_PRINTER_DEV}" ]; then
    log "WARNING: Unlinking container printer ${INT_PRINTER_DEV}"
    unlink "${INT_PRINTER_DEV}"
    RESTART_OCTOPRINT=true
  fi
fi

# Is the container encironment set up to run the camera streamer?
if "${ENABLE_MJPG_STREAMER}"; then
  if "${SHOULD_ENABLE_CAMERA}"; then
    # Was the camera specified as an option and does the host device exist?
    if [ -e "${EXT_CAMERA_DEV}" ]; then
      EXT_MAJOR=$((16#$(stat -L -c "%t" "$EXT_CAMERA_DEV")))
      EXT_MINOR=$((16#$(stat -L -c "%T" "$EXT_CAMERA_DEV")))
      log "Found host camera ${EXT_CAMERA_DEV} (${EXT_MAJOR},${EXT_MINOR})"
      # does the internal camera device exist?
      if [ -e "${INT_CAMERA_DEV}" ]; then
        INT_MAJOR=$((16#$(stat -L -c "%t" "${INT_CAMERA_DEV}")))
        INT_MINOR=$((16#$(stat -L -c "%T" "${INT_CAMERA_DEV}")))
        # both exist - do they match?
        if [ "${EXT_MAJOR}" = "${INT_MAJOR}" -a "${EXT_MINOR}" = "${INT_MINOR}" ]; then
          log "Host and container cameras linked"
        else
          log "WARNING Re-linking camera ${INT_CAMERA_DEV}"
          unlink "${INT_CAMERA_DEV}"
          mknod "${INT_CAMERA_DEV}" c "${EXT_MAJOR}" "${EXT_MINOR}"
          # restart the streaming service
          s6-svc -r /var/run/s6/services/mjpg-streamer
        fi
      else
        log "Linking container camera ${INT_CAMERA_DEV} to host (${EXT_MAJOR},${EXT_MINOR})"
        mknod "${INT_CAMERA_DEV}" c "${EXT_MAJOR}" "${EXT_MINOR}"
        # bring up the streaming service
        s6-svc -u /var/run/s6/services/mjpg-streamer
      fi
    else
      log "WARNING: Host camera ${EXT_CAMERA_DEV} does not exist"
      if [ -e "${INT_CAMERA_DEV}" ]; then
        log "WARNING: Unlinking container camera ${INT_CAMERA_DEV}"
        unlink "${INT_CAMERA_DEV}"
        # stop the streaming service
        s6-svc -d /var/run/s6/services/mjpg-streamer
      fi
    fi
  else
    log "No camera service configured"
    if [ -e "${INT_CAMERA_DEV}" ]; then
      log "WARNING: Unlinking container camera ${INT_CAMERA_DEV}"
      unlink "$INT_CAMERA_DEV"
      # stop the streaming service
      s6-svc -d /var/run/s6/services/mjpg-streamer
    fi
  fi
else
  log "ENABLE_MJPG_STREAMER disabled in docker-compose.yml"
fi

# should OctoPrint be restarted ?
if "${RESTART_OCTOPRINT}"; then
  log "Restarting OctoPrint service"
  s6-svc -r /var/run/s6/services/octoprint
fi
