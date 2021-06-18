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
        echo -e "## Conf file for passmanager\nName: $USER\nSFTPHost: \nSFTPPort:" > "$DIR/passmanager.conf"
        echo -e "$green OK"

        echo -e "$blue Generating keys..."
        openssl genrsa -out "$DIR/private.key" 2048
        openssl rsa -in "$DIR/private.key" -pubout -out "$DIR/public.key"
        echo -e "$green OK"

        echo -e "$blue Applying rights..."
        chown -R $USER "$DIR/"
        echo -e "$green OK"
    fi
elif [ "$1" == "get" ]
then
    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    sftphost=$(cat $DIR/passmanager.conf | grep SFTPHost | awk '{ print $2 }')
    sftpport=$(cat $DIR/passmanager.conf | grep SFTPPort | awk '{ print $2 }')

    mkdir -p /tmp/passmanager/get/
    #user=$(zenity --entry --title "Name request" --text "Please enter user to get :")

    sftp -P $sftpport $sftphost:/$user$name.gz.enc /tmp/passmanager/get/$user$name.gz.enc > /dev/null
    sftp -P $sftpport $sftphost:/$user$name.bin.enc /tmp/passmanager/get/$user$name.bin.enc > /dev/null
    openssl rsautl -decrypt -inkey $DIR/private.key -in /tmp/passmanager/get/$user$name.bin.enc -out /tmp/passmanager/get/$user$name.bin
    openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -in /tmp/passmanager/get/$user$name.gz.enc -out /tmp/passmanager/get/$user$name.gz -pass file:/tmp/passmanager/get/$user$name.bin
    gzip -d /tmp/passmanager/get/$user$name.gz
    rm /tmp/passmanager/get/$user$name*
elif [ "$1" == "send" ]
then
    name=$(cat $DIR/passmanager.conf | grep Name | awk '{ print $2 }')
    sftphost=$(cat $DIR/passmanager.conf | grep SFTPHost | awk '{ print $2 }')
    sftpport=$(cat $DIR/passmanager.conf | grep SFTPPort | awk '{ print $2 }')

    mkdir -p /tmp/passmanager/send/
    #allow_users=$(zenity --entry --title "Name request" --text "Please enter allow users :")
 
    if [ "$allow_users" == "" ]
    then
        lastuser=$(cat $DIR/passmanager.conf | grep LastUser | awk '{ print $2 }')
        allow_users=$lastuser
    #Fix by moving this block after the else block
    elif [ -f "$DIR/group.d/$allow_users" ]
    then
        give_users=$allow_users
        allow_users=$(cat $DIR/group.d/$allow_users)
    fi

    users=$(echo $allow_users | tr ", " "\n")

    for user in $users
    do
        targets=$(xclip -selection clipboard -t TARGETS -o)

	if echo "$targets" | grep image > /dev/null
        then
            xclip -selection clipboard -o -t image/png > "/tmp/passmanager/send/$name$user"
        else
            xclip -selection clipboard -o > "/tmp/passmanager/send/$name$user"
        fi
        gzip /tmp/passmanager/send/$name$user
        openssl rand -base64 32 > "/tmp/passmanager/send/$name$user.bin"
        openssl rsautl -encrypt -pubin -inkey "$DIR/users.d/$user.conf" -in "/tmp/passmanager/send/$name$user.bin" -out "/tmp/passmanager/send/$name$user.bin.enc"
        openssl enc -aes-256-cbc -md sha512 -pbkdf2 -salt -in /tmp/passmanager/send/$name$user.gz -out /tmp/passmanager/send/$name$user.gz.enc -pass file:/tmp/passmanager/send/$name$user.bin
        sftp -P $sftpport $sftphost <<< $"put /tmp/passmanager/send/$name$user.gz.enc" > /dev/null
        sftp -P $sftpport $sftphost <<< $"put /tmp/passmanager/send/$name$user.bin.enc" > /dev/null
        rm /tmp/passmanager/send/$name$user*
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
    read -p "Please copy the public key in your clipboard before click on OK !" ssh_key
    echo -e "$blue Adding User..."
    echo $ssh_key > "$DIR/users.d/$user.conf"
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
else
    echo -e "$red Unknown option"
    exit 1
fi
