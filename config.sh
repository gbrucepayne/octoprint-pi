#!/bin/bash
CONFIG_FILE="/boot/config.txt"
if ! grep -q "gpio=" "${CONFIG_FILE}"; then
  echo -e "# 3D printer control via GPIO\ngpio=5=op,dl\ngpio=6=ip,pd" >> "${CONFIG_FILE}"
fi