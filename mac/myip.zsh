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
# Get wired interface: prefer first in service order with IPv4 and active link
wired=$(networksetup -listnetworkserviceorder |grep -E "10/100|Ethernet" -A1 |grep -i hardware |awk '{print $NF}' |sed 's/)//')
wiredlink=""
if [[ -n "$wired" ]]; then
    # Iterate through all USB 10/100 entries in service order, pick first with IPv4 AND active link
    while IFS= read -r iface; do
        if ifconfig "$iface" 2>/dev/null | grep -q "inet " && ifconfig "$iface" 2>/dev/null | grep -q "status: active"; then
            wired=$iface
            wiredlink=$(ifconfig "$iface" 2>/dev/null | grep "inet " | awk '{print $1}')
            break
        fi
    done <<< "$wired"
fi

# Get wireless interface: prefer first in service order with IPv4 and active link
wireless=$(networksetup -listnetworkserviceorder |grep -A1 "Wi-Fi" |grep -i hardware |awk '{print $NF}' |sed 's/)//')
wirelesslink=""
if [[ -n "$wireless" ]]; then
    # Iterate through all Wi-Fi entries in service order, pick first with IPv4 and active link
    while IFS= read -r iface; do
        if ifconfig "$iface" 2>/dev/null | grep -q "inet " && ifconfig "$iface" 2>/dev/null | grep -q "status: active"; then
            wireless=$iface
            wirelesslink=$(ifconfig "$iface" 2>/dev/null | grep "inet " | awk '{print $1}')
            break
        fi
    done <<< "$wireless"
fi


# Internet IPs
inetv4=$(dig +short myip.opendns.com @resolver1.opendns.com)
inetv6=$(dig AAAA +short myip.opendns.com @resolver1.opendns.com)

# Internet Location
if [[ ! -z $inetv4 ]]; then
    inetorg=$(whois $inetv4 |grep -i orgname |awk -F":" '{print $2}' |xargs 2>/dev/null)
    inetloc=$(curl "ipinfo.io/$inetv4?token=$IPINFO_TOKEN" 2>/dev/null |jq -r '.city,.region,.country' |tr '\n' ',' |sed 's/\(.*\),/\1 /' |xargs)
fi

# Functions
display_ipinfo() {
    if [[ ! -z $wiredlink ]]; then
        # Wired IPv4
        localv4=$(ifconfig $wired |grep "inet " |awk '{print $2}')
        echo && echo "${BLUE}${BOLD}${ETHERNET_ICON} Ethernet IPv4:${RESET} ${GREEN}`echo $localv4`${RESET}"
    fi

    if [[ ! -z $wiredlink ]]; then
        # Wired IPv6
        localv6=$(ifconfig $wired 2>/dev/null |grep "inet6 " |grep -v "fe80::" |awk '{print $2}')
        if [[ ! -z $localv6 ]]; then
            echo "${BLUE}${BOLD}${ETHERNET_ICON} Ethernet IPv6:${RESET} ${GREEN}`echo $localv6`${RESET}"
        fi
    fi

    if [[ ! -z $inetv4 ]]; then
        echo && echo "${CYAN}${BOLD}${INTERNET_ICON} Internet IPv4:${RESET} ${GREEN}$inetv4${RESET}"
    fi

    if [[ ! -z $inetv6 ]]; then
        echo "${CYAN}${BOLD}${INTERNET_ICON} Internet IPv6:${RESET} ${GREEN}$inetv6${RESET}"
    fi

    if [[ ! -z $inetorg ]]; then
        echo "${CYAN}${BOLD}${INTERNET_ICON} Internet Org:${RESET} ${GREEN}$inetorg${RESET}"
    fi

    if [[ ! -z $inetloc ]]; then
        echo "${CYAN}${BOLD}${LOCATION_ICON} Internet Location:${RESET} ${GREEN}${inetloc//,/, }${RESET}"
    fi

    if [[ ! -z $wirelesslink ]]; then
        # Wireless IPv4
        wirelessv4=$(ifconfig $wireless |grep "inet " |awk '{print $2}')
        echo && echo "${YELLOW}${BOLD}${WIFI_ICON} Wireless IPv4:${RESET} ${GREEN}`echo $wirelessv4`${RESET}"
    fi

    if [[ ! -z $wirelesslink ]]; then
        # Wireless IPv6
        wirelessv6=$(ifconfig $wireless 2>/dev/null |grep "inet6 " |grep -v "fe80::" |awk '{print $2}')
        if [[ ! -z $wirelessv6 ]]; then
            echo "${YELLOW}${BOLD}${WIFI_ICON} Wireless IPv6:${RESET} ${GREEN}`echo $wirelessv6`${RESET}"
        fi
    fi
}

display_ipinfo
