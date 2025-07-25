#!/usr/bin/env zsh
# Display IP information for all active Interfaces and VPN
# Usage: myip.zsh

# Icons
ETHERNET_ICON="🔌"
WIFI_ICON="📶"
INTERNET_ICON="🌐"
VPN_ICON="🔒"
LOCATION_ICON="📍"

# Color definitions
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
GRAY="\033[37m"

# Interfaces
wired=$(networksetup -listnetworkserviceorder |grep -A1 "USB 10/100/1000 LAN" |grep -i hardware |awk '{print $NF}' |sed 's/)//')
wireless=$(networksetup -listnetworkserviceorder |grep -A1 "Wi-Fi" |grep -i hardware |awk '{print $NF}' |sed 's/)//')

# Link Status
wiredlink=$(ip link show |grep $wired |awk -F: '{print $1}')
wirelesslink=$(ip link show |grep $wireless |awk -F: '{print $1}')

# Internet IPs
inetv4=$(curl -s ifconfig.io/ip)
inetv6=$(curl -s -6 ifconfig.io/ip)

# Internet Location
inetorg=$(whois $inetv4 |grep -i orgname |awk -F":" '{print $2}' |xargs)
inetloc=$(curl "ipinfo.io/$inetv4?token=$IPINFO_TOKEN" 2>/dev/null |jq -r '.city,.region,.country' |tr '\n' ',' |sed 's/\(.*\),/\1 /' |xargs)

# VPN IPs
vpnhost="cicd.dc"

# Functions
display_ipinfo() {
    if [[ ! -z $wiredlink ]]; then
        # Wired IPv4
        localv4=$(ifconfig --interface $wired |grep "inet address" |awk '{print $NF}')

        echo && echo "${BLUE}${BOLD}${ETHERNET_ICON} Ethernet IPv4:${RESET} ${GREEN}`echo $localv4`${RESET}"
    fi

    if [[ ! -z $localv6 ]]; then
        # Wired IPv6
        localv6=$(ip addr sh $wired |grep inet6 |grep "autoconf secured" |awk '{print $2}')

        echo "${BLUE}${BOLD}${ETHERNET_ICON} Ethernet IPv6:${RESET} ${GREEN}`echo $localv6`${RESET}"
    fi

    echo && echo "${CYAN}${BOLD}${INTERNET_ICON} Internet IPv4:${RESET} ${GREEN}$inetv4${RESET}"

    if [[ ! -z $inetv6 ]]; then
        echo "${CYAN}${BOLD}${INTERNET_ICON} Internet IPv6:${RESET} ${GREEN}$inetv6${RESET}"
    fi

    echo "${CYAN}${BOLD}${INTERNET_ICON} Internet Org:${RESET} ${GREEN}$inetorg${RESET}"
    
    if [[ ! -z $inetloc ]]; then
        echo "${CYAN}${BOLD}${LOCATION_ICON} Internet Location:${RESET} ${GREEN}${inetloc//,/, }${RESET}"
    fi

    if [[ ! -z $wirelesslink ]]; then
        # Wireless IPv4
        wirelessv4=$(ifconfig --interface $wireless |grep "inet address" |awk '{print $NF}')

        echo && echo "${YELLOW}${BOLD}${WIFI_ICON} Wireless IPv4:${RESET} ${GREEN}`echo $wirelessv4`${RESET}"
    fi

    if [[ ! -z $wirelessv6 ]]; then
        # Wireless IPv6
        wirelessv6=$(ip addr sh $wireless |grep inet6 |grep "autoconf secured" |awk '{print $2}')

        echo "${YELLOW}${BOLD}${WIFI_ICON} Wireless IPv6:${RESET} ${GREEN}`echo $wirelessv6`${RESET}"
    fi
}

if route get $vpnhost |grep destination |awk '{print $NF}' |grep -q '10.'; then
    display_ipinfo

    # VPN IPs
    tunnel=$(route get $vpnhost |grep interface |awk '{print $NF}')
    workvpn=$(ifconfig --interface $tunnel |grep "inet address" |awk '{print $NF}')
    workvpnroute=$(route get $vpnhost |grep "route to" |awk '{print $NF}')
    vpncommand=$(route get $vpnhost |grep destination |awk '{print $NF}')

    echo && echo "${MAGENTA}${BOLD}${VPN_ICON} Work VPN IPv4:${RESET} ${GREEN}$workvpn${RESET}"
    echo "${MAGENTA}${BOLD}${VPN_ICON} Work VPN Route:${RESET} ${GREEN}$workvpnroute${RESET}"
else
    display_ipinfo
fi
