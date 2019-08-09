#!/bin/bash

if [[ $# -eq 1 ]]; then
    bck_folder=$1

    read -sp 'GitLab Personal Access Token (https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html): ' gitlab_password
    echo

    read -p 'GitHub Username: ' github_username
    read -sp 'GitHub Password (If you have 2FA enabled use a "personal access token" (https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)): ' github_password
    echo

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

    gitlab_reps=""

    #Get GitLab users projects
    for user in $gitlab_users; do
        i=1
        reps=$(curl -s "https://gitlab.com/api/v4/users/$user/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
        gitlab_reps=$gitlab_reps$'\n'$reps
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
        gitlab_reps=$gitlab_reps$'\n'$reps
        while [[ $reps != "" ]]; do
            i=$((i+1))
            reps=$(curl -s "https://gitlab.com/api/v4/users/$group/projects?private_token=$gitlab_password&page=$i" | grep -Po "\"path_with_namespace\":\"\K[^\"]*")
            gitlab_reps=$gitlab_reps$'\n'$reps
        done
    done

    #Get GitHub repositories
    i=1
    reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
    github_reps=$reps
    while [[ $reps != "" ]]; do
        i=$((i+1))
        reps=$(curl -s -u "$github_username:$github_password" "https://api.github.com/user/repos?page=$i" | sed -n 's/[^"]*"full_name": "\([^"]*\)".*/\1/p')
        github_reps=$github_reps$'\n'$reps
    done

    for rep in $gitlab_reps; do
        echo $rep
    done

    for rep in $github_reps; do
        echo $rep
    done

    echo "Backup exit with success!"
else
    echo "Usage: ./backup_reps.sh <path for backup>"
fi
