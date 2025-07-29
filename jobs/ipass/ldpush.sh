#!/usr/bin/env bash
# Usage: ./script hostname redhat5|redhat6|ubuntu

rsync -avphr ~/Dropbox/Configs/ldap/nss/certs root@"$1":~/new/
rsync -avphr ~/Dropbox/Configs/ldap/nss/"$2"/ root@"$1":~/new/
