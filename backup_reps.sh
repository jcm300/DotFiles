#!/bin/bash

#TODO: check curl errors (https://stackoverflow.com/questions/38905489/how-to-check-if-curl-was-successful-and-print-a-message)

getFromGitLab() {
    i=1
    aux=$(curl -s "https://gitlab.com/api/v4/$1?private_token=$2&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
    res=$aux
    while [[ $aux != "" ]]; do
        i=$((i+1))
        aux=$(curl -s "https://gitlab.com/api/v4/$1?private_token=$2&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
        res=$res$'\n'$aux
    done

    echo "$res"
}

getGitLabReps() {
    i=1
    reps=$(curl -s "https://gitlab.com/api/v4/$1/projects?private_token=$2&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
    all_reps=$reps
    while [[ $reps != "" ]]; do
        i=$((i+1))
        reps=$(curl -s "https://gitlab.com/api/v4/$1/projects?private_token=$2&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
        all_reps=$all_reps$'\n'$reps
    done

    echo "$all_reps"
}

getGitHubReps() {
    all_reps=""
    if [[ ! -z $1 ]] && [[ ! -z $2 ]]; then
        i=1
        reps=$(curl -s -u "$1:$2" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
        all_reps=$reps
        while [[ $reps != "" ]]; do
            i=$((i+1))
            reps=$(curl -s -u "$1:$2" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
            all_reps=$all_reps$'\n'$reps
        done
    fi

    echo "$all_reps"
}

updateReps() {
    for rep in $1; do
        folder=$2_$(echo $rep | sed "s/\//_/g")

        if [ ! -d $folder ]; then
            git clone https://$3:$4@$2.com/$rep.git $folder
            cd $folder
            git remote set-url origin https://$2.com/$rep.git
            cd ..
        else
            cd $folder
            git remote set-url origin https://$3:$4@$2.com/$rep.git    
            git pull --all
            git remote set-url origin https://$2.com/$rep.git
            cd ..
        fi
    done
}

if [[ $# -eq 1 ]]; then

    ## Get input (passwords and backup folder path)

    bck_folder=$1

    [ ! -d $bck_folder ] && mkdir -p $bck_folder
    [ ! -d $bck_folder ] && echo "Directory $bck_folder does not exists." && exit 1

    echo "Backup GitHub and GitLab repositories:"
    echo
    echo "WARNING: During backup passwords and personal access tokens will appear in top or ps commands!"
    echo 
    echo "Leave GitLab Username or/and GitLab Personal Access Token blank if you don't want to backup GitLab repositories."
    echo "Leave GitHub Username or/and GitHub Password blank if you don't want to backup GitHub repositories."
    echo

    echo "WARNING: The scope for the GitLab Personal Access Token should be 'api'. If is not will appears only public repositories."
    echo "WARNING: The scope for the GitHub Personal Access Token should be 'repo'. If is not will appears only public repositories."
    echo

    read -p 'GitLab Username: ' gitlab_username
    read -sp 'GitLab Personal Access Token (https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html): ' gitlab_password
    echo

    echo

    read -p 'GitHub Username: ' github_username
    read -sp 'GitHub Password (If you have 2FA enabled use a "personal access token" (https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)): ' github_password
    echo

    echo

    ## Get user repositories from GitLab

    gitlab_reps=""
    if [[ ! -z $gitlab_username ]] && [[ ! -z $gitlab_password ]]; then
        #Get GitLab Groups
        gitlab_groups=$(getFromGitLab "groups" $gitlab_password)

        #Get GitLab Namespaces(Groups + Users)
        gitlab_namespaces=$(getFromGitLab "namespaces" $gitlab_password)

        #Get GitLab Users
        gitlab_users=""
        for name in $gitlab_namespaces; do
            if [[ "$gitlab_groups" != *"$name"* ]]; then
                gitlab_users=$gitlab_users$'\n'$name
            fi
        done

        #Get GitLab users projects
        for user in $gitlab_users; do
            gitlab_reps=$gitlab_reps$'\n'$(getGitLabReps "users/$user" $gitlab_password)
        done

        #Get GitLab groups projects
        for group in $gitlab_groups; do
            gitlab_reps=$gitlab_reps$'\n'$(getGitLabReps "groups/$group" $gitlab_password)
        done
    fi

    ## Get user repositories from GitHub

    github_reps="$(getGitHubReps $github_username $github_password)"

    ## Perform backup

    cd $bck_folder

    updateReps "$gitlab_reps" "gitlab" $gitlab_username $gitlab_password
    updateReps "$github_reps" "github" $github_username $github_password

    echo
    echo "GitLab Repositories Backup:"
    echo "$gitlab_reps"
    echo
    echo "GitHub Repositories Backup:"
    echo "$github_reps"
    echo
    echo "Backup exit with success!"
else
    echo "Usage: ./backup_reps.sh <path for backup>"
fi
