#!/bin/bash

if [[ $# -eq 1 ]]; then
    bck_folder=$1

    read -p 'GitLab Username: ' gitlab_username
    read -sp 'GitLab Password: ' gitlab_password
    echo

    read -p 'GitHub Username: ' github_username
    read -sp 'GitHub Password (If you have 2FA enabled use a "personal access token" (https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)): ' github_password
    echo

    i=1
    reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
    github_reps=$reps
    while [[ $reps != "" ]]; do
        i=$((i+1))
        reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
        github_reps=$github_reps$'\n'$reps
    done

    for rep in $github_reps; do
        echo $rep
    done

    echo "Backup exit with success!"
else
    echo "Usage: ./backup_reps.sh <path for backup>"
fi
