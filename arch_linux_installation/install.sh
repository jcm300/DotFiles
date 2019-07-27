#!/bin/bash

klayout=pt-latin9
font=Lat2-Terminus16
wifi_interface=wlp2s0
country=Portugal
timezone=Europe/Lisbon
locale=pt_PT.UTF-8
hostname=asusS410UN

escape_text_for_sed(){
    text="$1"

    # escape all backslashes first
    text="${text//\\/\\\\}"

    # escape slashes
    text="${text//\//\\/}"

    # escape asterisks
    text="${text//\*/\\*}"

    # escape full stops
    text="${text//./\\.}"

    # escape [ and ]
    text="${text//\[/\\[}"
    text="${text//\[/\\]}"

    # escape ^ and $
    text="${text//^/\\^}"
    text="${text//\$/\\\$}"

    echo "$text"
}

#Set keyboard layout
loadkeys $klayout
setfont $font

#Connect to the internet via wireless
wifi-menu -o $wifi_interface

#Update/Sync system clock
timedatectl set-ntp true

#Partitioning
sfdisk /dev/sda < sda.sfdisk

#Formating the partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

#Mounting the partitions
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

#Enable Mirrors (put $country mirrors at first)
mirrorfile="/etc/pacman.d/mirrorlist"
servers="$(grep -A 1 "$country" $mirrorfile)"
servers="$(echo "$servers" | sed '/--/d')"
while read -r line; do
    line="$(escape_text_for_sed "$line")"

    sed "/$line/d" -i $mirrorfile
done <<< "$servers"
echo "$(head -n 6 $mirrorfile)" $'\n\n'"$servers" "$(tail -n +6 $mirrorfile)" > $mirrorfile

#Install base packages
pacstrap -i /mnt base base-devel

#fstab
genfstab -U /mnt >> /mnt/etc/fstab

#chroot
arch-chroot /mnt

#time zone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc --utc

#localization
sed -i "s/#$locale\(.*\)/$locale\1/" /etc/locale.gen
locale-gen
echo "KEYMAP=$klayout"$'\n'"FONT=$font" > /etc/vconsole.conf
echo "LANG=$locale" > /etc/locale.conf

#Network configuration
echo "$hostname" > /etc/hostname
echo "127.0.0.1   localhost"$'\n'"::1         localhost"$'\n'"127.0.1.1   $hostname.localdomain      $hostname" > /etc/hosts

#Initramfs
mkinitcpio -p linux

#install all packages
cat "my_packages" | xargs sudo pacman -S --noconfirm
