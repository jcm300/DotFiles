#!/bin/bash
PATH=/opt/someApp/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BATTINFO=$(acpi -b)
BATTGREP=$(echo "$BATTINFO" | grep Discharging)
BATTLEVEL=$(echo "$BATTINFO" | grep -P -o '[0-9]+(?=%)')
if [[ "$BATTLEVEL" -le 15 && "$BATTGREP" == "$BATTINFO" ]];
then
    export DISPLAY=:0
    /usr/bin/notify-send "Low Battery" "$BATTINFO"
fi
