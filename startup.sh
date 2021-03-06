#!/bin/bash

FRAMEBUFFER=fb0
HOMEPAGE=http://ufi.mom.net.wurstsalat.cloud/

# get framebuffer size
res=$(cat /sys/class/graphics/${FRAMEBUFFER:-fb0}/virtual_size | awk -F ',' '{ print $1 + 1 "," $2 + 1 }')

displayname=$(cat /boot/displayname.txt)

# cleanup and prepare temp folders to prevent chromium from complaining
rm -rf /tmp/chromium
mkdir -p /tmp/chromium
rm -rf /tmp/pki
mkdir -p /tmp/pki

chromium-browser \
  --window-size=${res} \
  --window-position=0,0 \
  --disable-features=TranslateUI \
  --disble-extensions \
  --disable-component-update \
  --check-for-update-interval=31536000 \
  --disable-restore-session-state \
  --disable-session-crashed-bubble \
  --noerrdialogs \
  --incognito \
  --disable-sync \
  --disable-notifications \
  --no-experiments \
  --disable-audio \
  --ignore-gpu-blacklist \
  --enable-webgl \
  --user-data-dir=/tmp/chromium \
  --disk-cache-dir=/tmp/chromium \
  --disk-cache-size=0 \
  --kiosk \
  "${HOMEPAGE:-https://duckduckgo.com/}?name=${displayname}" >> /tmp/chromium.log 2>&1
