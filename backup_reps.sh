#!/bin/bash

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
        i=1
        groups=$(curl -s "https://gitlab.com/api/v4/groups?private_token=$gitlab_password&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
        gitlab_groups=$groups
        while [[ $groups != "" ]]; do
            i=$((i+1))
            groups=$(curl -s "https://gitlab.com/api/v4/groups?private_token=$gitlab_password&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
            gitlab_groups=$gitlab_groups$'\n'$groups
        done

        #Get GitLab Namespaces(Groups + Users)
        i=1
        namespaces=$(curl -s "https://gitlab.com/api/v4/namespaces?private_token=$gitlab_password&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
        gitlab_namespaces=$namespaces
        while [[ $namespaces != "" ]]; do
            i=$((i+1))
            namespaces=$(curl -s "https://gitlab.com/api/v4/namespaces?private_token=$gitlab_password&page=$i" | grep -Po "\"full_path\":\"\K[^\"]*")
            gitlab_namespaces=$gitlab_namespaces$'\n'$namespaces
        done

        #Get GitLab Users
        gitlab_users=""
        for name in $gitlab_namespaces; do
            if [[ "$gitlab_groups" != *"$name"* ]]; then
                gitlab_users=$gitlab_users$'\n'$name
            fi
        done

        #Get GitLab users projects
        for user in $gitlab_users; do
            i=1
            reps=$(curl -s "https://gitlab.com/api/v4/users/$user/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
            gitlab_reps=$gitlab_reps$reps
            while [[ $reps != "" ]]; do
                i=$((i+1))
                reps=$(curl -s "https://gitlab.com/api/v4/users/$user/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
                gitlab_reps=$gitlab_reps$'\n'$reps
            done
        done

        #Get GitLab groups projects
        for group in $gitlab_groups; do
            i=1
            reps=$(curl -s "https://gitlab.com/api/v4/groups/$group/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
            gitlab_reps=$gitlab_reps$reps
            while [[ $reps != "" ]]; do
                i=$((i+1))
                reps=$(curl -s "https://gitlab.com/api/v4/users/$group/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
                gitlab_reps=$gitlab_reps$'\n'$reps
            done
        done
    fi

    ## Get user repositories from GitHub

    github_reps=""
    if [[ ! -z $github_username ]] && [[ ! -z $github_password ]]; then
        i=1
        reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
        github_reps=$reps
        while [[ $reps != "" ]]; do
            i=$((i+1))
            reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
            github_reps=$github_reps$'\n'$reps
        done
    fi

    ## Perform backup

    cd $bck_folder

    for rep in $gitlab_reps; do
        folder=gitlab_$(echo $rep | sed "s/\//_/g")

        if [ ! -d $folder ]; then
            git clone https://$gitlab_username:$gitlab_password@gitlab.com/$rep.git $folder
            cd $folder
            git remote set-url origin https://gitlab.com/$rep.git
            cd ..
        else
            cd $folder
            git remote set-url origin https://$gitlab_username:$gitlab_password@gitlab.com/$rep.git    
            git pull --all
            git remote set-url origin https://gitlab.com/$rep.git
            cd ..
        fi
    done

    for rep in $github_reps; do
        folder=github_$(echo $rep | sed "s/\//_/g")

        if [ ! -d $folder ]; then
            git clone https://$github_username:$github_password@github.com/$rep.git $folder
            cd $folder
            git remote set-url origin https://github.com/$rep.git
            cd ..
        else
            cd $folder
            git remote set-url origin https://$github_username:$github_password@github.com/$rep.git    
            git pull --all
            git remote set-url origin https://github.com/$rep.git
            cd ..
        fi
    done

    echo
    echo "GitLab Repositories Backup:"
    echo "$gitlab_reps"
    echo "GitHub Repositories Backup:"
    echo "$github_reps"
    echo "Backup exit with success!"
else
    echo "Usage: ./backup_reps.sh <path for backup>"
fi
