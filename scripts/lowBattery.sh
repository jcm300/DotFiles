#!/bin/bash

BATTINFO=$(acpi -b)
BATTGREP=$(echo "$BATTINFO" | grep Discharging)
BATTLEVEL=$(echo "$BATTINFO" | grep -P -o '[0-9]+(?=%)')
if [[ "$BATTLEVEL" -le 15 && "$BATTGREP" == "$BATTINFO" ]];
then
    /usr/bin/notify-send "Low Battery" "$BATTINFO"
fi
