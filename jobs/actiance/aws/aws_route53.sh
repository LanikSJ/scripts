#!/usr/bin/env bash

echo && echo "This Script will add or remove a hostname from AWS Route53." && echo
echo "What's domain? "
read domain

echo && echo "What's the hostname? "
read hostname

echo && echo "What type of record you want to add? (A, PTR)?"
read type

echo && echo "What's the IP address of your host? "
read ip

cat << MENU

 What do you want to do?

       1.  Create a record
       2.  Replace a record
       3.  Delete a record

MENU

printf "Enter choice [1-3, press any key to exit]: "

read channelchoice

case "$channelchoice"
in
  1)
	cli53 rrcreate $domain $hostname $type $ip --ttl 300
        ;;
  2)
	cli53 rrcreate $domain $hostname $type $ip --ttl 300 --replace
        ;;
  3)
	cli53 rrdelete $domain $hostname
        ;;
  *)
        echo && echo This script will now exit!
        exit 0
        ;;

esac
