start-pulseaudio-x11
systemctl --user import-environment DISPLAY
/usr/lib/geoclue-2.0/demos/agent &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
pgrep redshift-gtk &> /dev/null || redshift-gtk &> /dev/null &
thunderbird &
nextcloud &
exec i3
