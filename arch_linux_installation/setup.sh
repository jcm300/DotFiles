#!/bin/bash

if [[ $# -eq 2 ]]; then
    username=$1
    folder=$2
    backup=$folder/backup/
    ssid=Vodafone-2BBD47

    #Fix r8822be wifi problem
    sudo cp $folder/configs/wifiProblemFix/50-r8822be.conf /etc/modprobe.d/
    sudo mkinitcpio -p linux

    #network manager config
    cd $backup
    echo "Insert passphrase for Network Manager gpg:"
    gpg -d --passphrase-fd 0 --decrypt-files networkManager.tar.gpg
    sudo tar -xf networkManager.tar
    sudo rm -r networkManager.tar
    sudo rm -r /etc/NetworkManager/system-connections
    sudo mv system-connections /etc/NetworkManager/
    sudo systemctl start NetworkManager.service
    sudo systemctl enable NetworkManager.service
    echo "Connect to wifi:"
    nmcli device wifi connect $ssid --ask
    cd

    #Configure AUR and multilib
    sudo cp $folder/pacman.conf /etc/pacman.conf
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm git wget
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si
    cd
    sudo rm -r yay-bin

    #graphic environment
    sudo pacman -S --noconfirm xorg xorg-xinit xorg-twm mesa nvidia lib32-nvidia-utils bumblebee xf86-video-intel lib32-virtualgl
    sudo passwd -a $username bumblebee
    sudo systemctl enable bumblebeed.service

    #Audio Drivers
    sudo pacman -S --noconfirm alsa-firmware alsa-utils alsa-plugins pulseaudio-alsa pulseaudio

    #Install i3
    sudo pacman -S --noconfirm i3 rofi

    #Power Management
    sudo pacman -S --noconfirm tlp
    tlp start

    #Screen brightness
    yay -S --noconfirm light-git

    #Low Batery Notifications and General Notifications 
    sudo pacman -S --noconfirm dunst cronie
    (crontab -l 2>/dev/null; echo "*/5 * * * * /home/$username/.config/dunst/lowBattery.sh") | crontab -

    #Oh-My-Zsh Installation
    chsh -s /usr/bin/zsh
    sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

    #Install packages
    cat "$folder/packages" | xargs yay -S --noconfirm

    #Configs
    cd $backup
    mkdir -p ~/.mozilla/firefox/
    sudo rm -r ~/.mozilla/firefox/*.default
    cp -r *.default ~/.mozilla/firefox/
    echo "Insert passphrase for Thunderbird gpg:"
    gpg -d --passphrase-fd 0 --decrypt-files thunderbird.tar.gpg
    tar -xf thunderbird.tar
    rm -r thunderbird.tar
    rm -r ~/.thunderbird
    mv .thunderbird ~/
    openssl aes-256-cbc -d -a -salt -pbkdf2 -in keys.tar.aes -out keys.tar
    tar -xvf keys.tar
    rm -r keys.tar
    rm -r ~/.ssh
    rm -r ~/.gnupg
    mv .ssh ~/
    mv .gnupg ~/
    chmod 600 ~/.ssh/*
    sudo find ~/.gnupg -type f -exec chmod 600 {} \;
    sudo find ~/.gnupg -type d -exec chmod 700 {} \;
    git config --global user.signingkey BA459457D597C33C
    echo "Insert passphrase for ProtonVPN gpg:"
    gpg -d --passphrase-fd 0 --decrypt-files protonVPN.tar.gpg
    sudo tar -xf protonVPN.tar
    sudo rm -r protonVPN.tar
    sudo rm -r ~/.protonvpn-cli
    sudo mv .protonvpn-cli ~/
    cd

    cd $folder/configs
    cp xorg/* ~/
    cp zsh/* ~/
    cp -r alacritty dunst i3 rofi zathura ~/.config/
    mkdir ~/.vim
    cp vim/* ~/.vim/
    cp theme/* /usr/share/icons/default/
    cp firewall/* /etc/
    cd

    #Vim-plug
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -c "PlugUpgrade" -c "PlugInstall" -c "PlugUpdate" -c ":q" -c ":q" ~/.vim/vimrc #install plugins

    #DisableTPM
    sudo cp $folder/configs/disableTPM/blacklist.conf /etc/modprobe.d/
    sudo mkinitcpio -p linux

    #Lock Screen
    sudo cp $folder/configs/lockScreen/lockScreen.service /etc/systemd/system/
    sudo systemctl start lockScreen.service
    sudo systemctl enable lockScreen.service

    #Remove desktop folder from home
    cp $folder/configs/removeDesktopFolder/user-dirs.dirs ~/.config/

    #HP Printer
    sudo pacman -S --noconfirm hplip
    echo "Call hplip -i to setup a printer"
    read -n 1

    #reboot
    reboot
else
    echo "Usage: ./setup.sh <username> <path for folder with backup and configs>"
fi
