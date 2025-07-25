#!/usr/bin/env bash
# This script will do a DNS flush and restart.

sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
