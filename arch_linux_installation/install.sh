#!/bin/bash

klayout=pt-latin9
font=Lat2-Terminus16
wifi_interface=wlp2s0
country=Portugal
timezone=Europe/Lisbon
locale=pt_PT.UTF-8
hostname=asusS410UN
username=jcm300
cpu=intel #or amd

DIR="$(cd "$(dirname "$0")" && pwd)"

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

#Fix r8822be wifi problem
modprobe -rv r8822be
modprobe -v r8822be aspm=0

#Set keyboard layout
loadkeys $klayout
setfont $font

#Connect to the internet via wireless
wifi-menu -o $wifi_interface

#Update/Sync system clock
timedatectl set-ntp true

#Partitioning
sfdisk /dev/sda < $DIR/sda.sfdisk

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
pacstrap /mnt base base-devel

#fstab
genfstab -U /mnt >> /mnt/etc/fstab

#time zone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

#localization
arch-chroot /mnt sed -i "s/#$locale\(.*\)/$locale\1/" /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "KEYMAP=$klayout"$'\n'"FONT=$font" > /mnt/etc/vconsole.conf
arch-chroot /mnt echo "LANG=$locale" > /mnt/etc/locale.conf

#Network configuration
arch-chroot /mnt echo "$hostname" > /mnt/etc/hostname
arch-chroot /mnt echo "127.0.0.1   localhost"$'\n'"::1         localhost"$'\n'"127.0.1.1   $hostname.localdomain      $hostname" > /mnt/etc/hosts

#Initramfs
arch-chroot /mnt mkinitcpio -p linux

#Set root password
echo "Set root password:"
arch-chroot /mnt passwd

#Add a new user
arch-chroot /mnt useradd -m -g users -G wheel -s /usr/bin/zsh $username

#Set password to new user
echo "Set $username password:"
arch-chroot /mnt passwd $username

#Install some necessary packages
arch-chroot /mnt sudo pacman -S --noconfirm zsh vim networkmanager ntfs-3g

#Allow members of group wheel to execute any command
arch-chroot /mnt sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers

#Change default shell to zsh
arch-chroot /mnt chsh -s /usr/bin/zsh

#Bootloader Installation
arch-chroot /mnt bootctl install
arch-chroot /mnt sudo pacman -S --noconfirm $cpu-ucode
arch-chroot /mnt echo "title   Arch Linux" > /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo "linux   /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo "initrd  /$cpu-ucode.img" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo "initrd  /initramfs-linux.img" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo "options root=/dev/sda2 rw" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo "default  arch"$'\n'"timeout  4"$'\n'"editor   0" > /mnt/boot/loader/loader.conf

#Reboot
umount -R /mnt
reboot
