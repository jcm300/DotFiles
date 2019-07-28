#!/bin/bash

if [[ $# -eq 2 ]]; then
    username=$1
    backup=$2

    #network manager config
    cd $backup
    gpg networkManager.tar.gpg
    tar -xf networkManager.tar
    rm -r networkManager.tar
    mv system-connections /etc/NetworkManager/
    systemctl start NetworkManager.service
    systemctl enable NetworkManager.service
    cd

    #Configure AUR and multilib
    cp $backup/pacman.conf /etc/pacman.conf
    pacman -Syu --noconfirm
    pacman -S --noconfirm yay

    #graphic environment
    pacman -S --noconfirm xorg xorg-xinit xorg-twm mesa nvidia lib32-nvidia-utils bumblebee xf86-video-intel lib32-virtualgl
    passwd -a $username bumblebee
    systemctl enable bumblebeed.service

    #Audio Drivers
    pacman -S --noconfirm alsa-firmware alsa-utils alsa-plugins pulseaudio-alsa pulseaudio

    #Install i3
    pacman -S --noconfirm i3 rofi

    #Power Management
    pacman -S --noconfirm tlp
    tlp start

    #Screen brightness
    yay -S --noconfirm light-git

    #Keyboard Backlight
    yay -S --noconfirm asus-kbd-backlight

    #Low Batery Notifications and General Notifications 
    pacman -S --noconfirm dunst cronie
    (crontab -l 2>/dev/null; echo "*/5 * * * * /home/$username/.config/dunst/lowBattery.sh") | crontab -

    #Oh-My-Zsh Installation
    chsh -s /usr/bin/zsh
    sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

    #Install packages
    cat "$backup/packages" | xargs yay -S --noconfirm

    #Configs
    cd $backup
    mkdir -p ~/.mozilla/firefox/
    mv *.default ~/.mozilla/firefox/
    gpg thunderbird.tar.gpg
    tar -xf thunderbird.tar
    rm -r thunderbird.tar
    mv .thunderbird ~/
    openssl aes-256-cbc -d -a -salt -pbkdf2 -in keys.tar.aes -out keys.tar
    tar -xvf keys.tar
    rm -r keys.tar
    mv .ssh ~/
    mv .gnupg ~/
    gpg protonVPN.tar.gpg
    tar -xf protonVPN.tar
    rm -r protonVPN.tar
    mv .protonvpn-cli ~/
    cd

    cd $backup/configs
    mv xorg/* ~/
    mv zsh/* ~/
    mv alacritty dunst i3 rofi zathura ~/.config/
    mkdir ~/.vim
    mv vim/* ~/.vim/
    mv theme/* /usr/share/icons/default/
    mv firewall/* /etc/
    cd

    #Vim-plug
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -c "PlugUpgrade" -c "PlugInstall" -c "PlugUpdate" -c ":q" -c ":q" ~/.vim/vimrc #install plugins

    #DisableTPM
    mv $backup/configs/disableTPM/blacklist.conf /etc/modprobe.d/
    mkinitcpio -p linux

    #Lock Screen
    mv $backup/configs/lockScreen/lockScreen.service /etc/systemd/system/
    systemctl start lockScreen.service
    systemctl enable lockScreen.service

    #Remove desktop folder from home
    mv $backup/configs/removeDesktopFolder/user-dirs.dirs ~/.config/

    #HP Printer
    pacman -S --noconfirm hplip
    echo "Call hplip -i to setup a printer"

    #reboot
    reboot
else
    echo "Usage: ./setup.sh <username> <path for backup>"
fi
