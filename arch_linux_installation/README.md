# Arch Linux Installation

If you have already a arch linux installation do a backup. In my case:
```
./make_backup.sh jcm300 ./arch_linux_installation/backup ~/Reps/DotFiles/configs
```

Then make a bootable USB pen with Arch Linux:
```
wget http://glua.ua.pt/pub/archlinux/iso/$version/archlinux-$version-x86_64.iso
wget http://glua.ua.pt/pub/archlinux/iso/$version/archlinux-$version-x86_64.iso.sig
gpg --keyserver-options auto-key-retrieve --verify archlinux-$version-x86_64.iso.sig
sudo dd bs=4M if=archlinux-$version-x86_64.iso of=/dev/sdx status=progress oflag=sync
sync
```

Copy to another pen the backup done on first pass and installation scripts:
```
sudo mount /dev/sdxY /mnt
cp -r * /mnt #arch_linux_installation folder
cp -r ../configs /mnt
sudo umount /dev/sdxY
```

Reboot into usb pen with Arch Linux.

Run script for base installation:
```
mount /dev/sdxY /mnt #pen with scripts and backup
./mnt/install.sh
```

Now the pc will reboot and you should go to the base arch linux installed instead of the arch linux bootable. There, you login and run:
```
mount /dev/sdxY /mnt #pen with scripts and backup
sudo ./mnt/setup.sh jcm300 /mnt #the first is the username, the last parameter is the path for the folder with backup
```

The pc will reboot one last time and the installation will be concluded. Now to start the graphical environment, login and run `startx`.
