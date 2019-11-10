#!/bin/bash

echo -n "Enter display name: "
read displayname
echo -n ${displayname} > /home/display/.displayname

apt -y install xorg chromium-browser fonts-noto-color-emoji unclutter ddcutil

adduser --system display

cat <<EOF > /home/display/.xinitrc
export STARTUP=/opt/ufi-display/startup.sh
. /etc/X11/Xsession
EOF
chown display:nogroup /home/display/.xinitrc

cat <<EOF > /etc/systemd/system/ufi-display.service
[Unit]
Description=ufi display util service
After=multi-user.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c '/bin/echo 0 > /sys/class/graphics/fbcon/cursor_blink'
ExecStart=/usr/bin/python3 -u /opt/ufi-display/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF
systemctl enable ufi-display.service

cat <<EOF > /etc/systemd/system/xinit.service
[Unit]
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/bin/xinit
User=display
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable xinit.service
systemctl disable getty@tty1.service

cat <<EOF > /etc/X11/Xsession.d/98x11-screen_blank
xset s off
xset -dpms
xset s noblank
EOF

sed -i \
-e 's/-idle [0-9]\+/-idle 0/g' \
-e 's/START_UNCLUTTER=.\+/START_UNCLUTTER="true"/g' \
/etc/default/unclutter

systemctl disable man-db.timer

sed -i \
-e 's/fsck\.repair=yes/fsck.repair=no/g' \
-e 's/ quiet / /g' \
-e 's/ logo.nologo / /g' \
-e 's/ vt\.global_cursor_default=. / /g' \
-e 's/ consoleblank=. / /g' \
-e 's/ fastboot / /g' \
-e 's/ noswap / /g' \
-e 's/rootwait/quiet logo.nologo vt.global_cursor_default=0 consoleblank=0 fastboot noswap rootwait/g' \
/boot/cmdline.txt 
