#!/bin/bash
CONFIG_FILE="/boot/config.txt"
if ! grep -q "gpio=4=op,dl" "${CONFIG_FILE}"; then
  echo -e "# 3D printer control via GPIO#4\ngpio=4=op,dl" >> "${CONFIG_FILE}"
fi