#!/bin/bash

red="\033[31m"
blue="\033[34m"
green="\033[32m"
default="\033[0m"

DIR="/home/$USER/.passmanager"

function join { local IFS="$1"; shift; echo "$*"; }

if [ "$1" == "init" ]
then
    if [ -d "$DIR" ]
    then
        echo -e "$blue Nothing to do, directory already exist"
    else
        echo -e "$blue Creating directories..."

        mkdir -p "$DIR/users.d/"
        mkdir -p "$DIR/group.d/"
        echo -e "$green OK"

        echo -e "$blue Generating conf file..."
        echo -e "## Conf file for passmanager\nName: $USER\nSFTPHost: \nSFTPPort: \nSFTPUser: " > "$DIR/passmanager.conf"
        echo -e "$green OK"

        echo -e "$blue Generating keys..."
        openssl genrsa -out "$DIR/private.key" 2048
        openssl rsa -in "$DIR/private.key" -pubout -out "$DIR/public.key"
        echo -e "$green OK"

        echo -e "$blue Copy key to users.d dir..."
        cp "$DIR/public.key" "$DIR/users.d/$USER.conf"
        echo -e "$green OK"

        echo -e "$blue Applying rights..."
        chown -R $USER "$DIR/"
        echo -e "$green OK"
    fi
elif [ "$1" == "getpwd" ]
then
    passwordname=$2

    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    sftphost=$(cat $DIR/passmanager.conf | grep SFTPHost | awk '{ print $2 }')
    sftpport=$(cat $DIR/passmanager.conf | grep SFTPPort | awk '{ print $2 }')
    sftpuser=$(cat $DIR/passmanager.conf | grep SFTPUser | awk '{ print $2 }')

    mkdir -p /tmp/passmanager/getpwd/
    read -p "Please enter the password creator : " creator

    sftp -P $sftpport $sftpuser@$sftphost:/$passwordname-$creator-$name.gz.enc /tmp/passmanager/getpwd/$passwordname-$creator-$name.gz.enc > /dev/null
    sftp -P $sftpport $sftpuser@$sftphost:/$passwordname-$creator-$name.bin.enc /tmp/passmanager/getpwd/$passwordname-$creator-$name.bin.enc > /dev/null
    openssl rsautl -decrypt -inkey $DIR/private.key -in /tmp/passmanager/getpwd/$passwordname-$creator-$name.bin.enc -out /tmp/passmanager/getpwd/$passwordname-$creator-$name.bin
    openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -in /tmp/passmanager/getpwd/$passwordname-$creator-$name.gz.enc -out /tmp/passmanager/getpwd/$passwordname-$creator-$name.gz -pass file:/tmp/passmanager/getpwd/$passwordname-$creator-$name.bin
    gzip -d /tmp/passmanager/getpwd/$passwordname-$creator-$name.gz
    echo -e "$red Password $passwordname :\n"
    cat /tmp/passmanager/getpwd/$passwordname-$creator-$name
    rm /tmp/passmanager/getpwd/$passwordname-$creator-$name*
elif [ "$1" == "addpwd" ]
then
    passwordname=$2

    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    sftphost=$(cat $DIR/passmanager.conf | grep SFTPHost | awk '{ print $2 }')
    sftpport=$(cat $DIR/passmanager.conf | grep SFTPPort | awk '{ print $2 }')
    sftpuser=$(cat $DIR/passmanager.conf | grep SFTPUser | awk '{ print $2 }')

    mkdir -p /tmp/passmanager/addpwd/
    read -p "Please enter allow users or group name (left empty if only you can access) and (separate them by a ',' if there is multiple user) : " allow_users
    read -p "Please enter the password : " password

    if [ "$allow_users" == "" ]
    then
        allow_users=$name
    elif [ -f "$DIR/group.d/$allow_users" ]
    then
        allow_users=$(cat $DIR/group.d/$allow_users)
    fi

    users=$(echo $allow_users | tr ", " "\n")

    for user in $users
    do
        echo "$password" > "/tmp/passmanager/addpwd/$passwordname-$name-$user"
        gzip /tmp/passmanager/addpwd/$passwordname-$name-$user
        openssl rand -base64 32 > "/tmp/passmanager/addpwd/$passwordname-$name-$user.bin"
        openssl rsautl -encrypt -pubin -inkey "$DIR/users.d/$user.conf" -in "/tmp/passmanager/addpwd/$passwordname-$name-$user.bin" -out "/tmp/passmanager/addpwd/$passwordname-$name-$user.bin.enc"
        openssl enc -aes-256-cbc -md sha512 -pbkdf2 -salt -in /tmp/passmanager/addpwd/$passwordname-$name-$user.gz -out /tmp/passmanager/addpwd/$passwordname-$name-$user.gz.enc -pass file:/tmp/passmanager/addpwd/$passwordname-$name-$user.bin
        sftp -P $sftpport $sftpuser@$sftphost <<< $"put /tmp/passmanager/addpwd/$passwordname-$name-$user.gz.enc" > /dev/null
        sftp -P $sftpport $sftpuser@$sftphost <<< $"put /tmp/passmanager/addpwd/$passwordname-$name-$user.bin.enc" > /dev/null
        rm /tmp/passmanager/addpwd/$passwordname-$name-$user*
    done
elif [ "$1" == "getpublickey" ]
then
    echo -e "$blue Public Key :$default\n"
    cat $DIR/public.key
elif [ "$1" == "getsftppublickey" ]
then
    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    echo -e "$blue SFTP Public Key :$default\n"
    ssh-keygen -e -f /home/$name/.ssh/id_rsa.pub
elif [ "$1" == "adduser" ]
then
    user=$2
    read -p 'Please copy the public key in your clipboard before press Enter ' ssh_key
    echo -e "$blue Adding User..."
    xclip -o > "$DIR/users.d/$user.conf"
elif [ "$1" == "group" ]
then
    if [ "$2" == "delete" ]
    then
        echo -e "$blue Removing Group..."
        group=$3
        rm $DIR/group.d/$group
        echo -e "$green OK"
    elif [ "$2" == "add" ]
    then
	if [ -z $3 ]
        then
            echo -e "$red Please provide group name"
        else
            group=$3
            read -p "Please enter the users list separated by , :" list_users
            echo -e "$blue Adding Group..."
            echo "$list_users" >> $DIR/group.d/$group
            echo -e "$green OK"
        fi
    elif [ "$2" == "adduser" ]
    then
        user=$3
        group=$4
        echo -e "$blue Adding $user to $group..."
        sed -Ei "s/(.*)/\1, $user/g" $DIR/group.d/$group
        echo -e "$green OK"
    elif [ "$2" == "deluser" ]
    then
        user=$3
        group=$4
        echo -e "$blue Removing $user from $group..."
        users=$(cat $DIR/group.d/$group | tr "," "\n")
        new_array=${users[@]/$user}
        echo "$(join ', ' ${new_array[@]})" > $DIR/group.d/$group
        echo -e "$green OK"
    else
        echo -e "$red Unknown option"
        exit 1
    fi
elif [ "$1" == "stat" ]
then
    if [ "$(ls -A $DIR/group.d/)" ]
    then
        for filename in $DIR/group.d/*
        do
            echo -e "$blue Group $(basename "$filename") :$default"
            cat $filename
            echo -e "\n"
        done
    else
        echo -e "$red No groups\n"
    fi
    echo -e "$blue Users :$default"
    for filename in $(ls $DIR/users.d/)
    do
        split=($(basename "$filename" | tr "." "\n"))
        echo "${split[0]}" 
    done
    echo -e "\n"
elif [ "$1" == "listpwd" ]
then
    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    sftphost=$(cat $DIR/passmanager.conf | grep SFTPHost | awk '{ print $2 }')
    sftpport=$(cat $DIR/passmanager.conf | grep SFTPPort | awk '{ print $2 }')
    sftpuser=$(cat $DIR/passmanager.conf | grep SFTPUser | awk '{ print $2 }')
    list_pwd=$(sftp -q -P $sftpport $sftpuser@$sftphost <<< $"ls *.gz.enc" | grep -v '^sftp>')
    printf "%-30s| %-20s\n" Titre Creator
    echo "**************************************************"
    for pwd_file in $list_pwd
    do
        nom=$(echo $pwd_file | awk -F '-' '{ print $1 }')
        creator=$(echo $pwd_file | awk -F '-' '{ print $2 }')
        destinator=$(echo $pwd_file | awk -F '-' '{ print $3 }' | awk -F '.' '{ print $1 }')
        if [ "$destinator" == "$name" ]
        then
	    printf "%-30s| %-20s\n" $nom $creator
        fi
    done
else
    echo -e "$red Unknown option"
    exit 1
fi
