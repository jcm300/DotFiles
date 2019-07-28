start-pulseaudio-x11
systemctl --user import-environment DISPLAY
/usr/lib/geoclue-2.0/demos/agent &
pgrep redshift-gtk &> /dev/null || redshift-gtk &> /dev/null &
thunderbird &
exec i3
