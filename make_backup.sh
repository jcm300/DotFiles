#!/bin/bash

partial_backup() {
    #firefox backup
    cp -r /home/$username/.mozilla/firefox/*.default $bf_local

    #home directory backup without hidden files on top-level
    mkdir $bf_home
    rsync -a --exclude="/${bf_local##*/}" --exclude="/.*" $home $bf_home

    #gpg and ssh keys
    tar -cf keys.tar -C $home .gnupg .ssh
    openssl aes-256-cbc -a -salt -pbkdf2 -in keys.tar -out $bf_local/keys.tar.aes
    rm keys.tar
    #extract
    #openssl aes-256-cbc -d -a -salt -pbkdf2 -in keys.tar.aes -out keys.tar
    #tar -xvf keys.tar
}

configs_backup() {
    mkdir $1 $1/vim $1/xorg $1/alacritty $1/dunst $1/i3 $1/rofi $1/zathura $1/zsh 

    #vim
    cp $vimfile $1/vim

    #arch configs
    cp $home/.xinitrc $1/xorg
    cp -r $home/.config/alacritty/* $1/alacritty
    cp -r $home/.config/dunst/* $1/dunst
    cp -r $home/.config/i3/* $1/i3
    cp -r $home/.config/rofi/* $1/rofi
    cp -r $home/.config/zathura/* $1/zathura
    cp $home/.zshrc $1/zsh
}

if [[ $# -eq 2 ]] || [[ $# -eq 3 ]]; then
    username=$1
    bf_local=${2%/}

    bf_home=$bf_local/home
    home=/home/$username/

    vimfile=$home/.vim/vimrc

    mkdir $bf_local

    partial_backup

    if [[ $# -eq 2 ]]; then
        configs_backup $bf_local/configs
    else
        configs_backup $3
        cd $3
        git add .
        git commit -m "new configs backup"
        git push origin master
    fi

    echo "Backup exit with success!"
else
    echo "Usage: ./make_backup.sh <username> <path for backup>"
    echo "or with rep for configs: ./make_backup.sh <username> <path for backup> <path of configs folder on rep>"
fi
