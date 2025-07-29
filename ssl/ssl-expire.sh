#!/bin/sh
# This script should work with sh, bash, and zsh
# Extract and display SSL certificate expiration information
#
# Usage: ssl-expire.sh [options] host [port]
#
# Options:
#   -h, --help              Display this help message
#   -d, --days-only         Display only days until expiration
#   -w, --warning DAYS      Warning threshold in days (default: 30)
#   -c, --no-color          Disable colored output
#   --debug                 Enable debug output
#
# Examples:
#   ssl-expire.sh example.com
#   ssl-expire.sh -d example.com
#   ssl-expire.sh -w 14 example.com 443
#
# Exit codes:
#   0 - Certificate is valid and not expiring soon
#   1 - Certificate is expiring soon (within warning threshold)
#   2 - Certificate has expired
#   3 - Error (invalid arguments, connection failure, etc.)

# Terminal colors - using POSIX-compatible test
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  RESET='\033[0m'
  INFO="ℹ"
  SUCCESS="✓"
  WARNING="⚠"
  ERROR="✗"
else
  GREEN=''
  YELLOW=''
  RED=''
  BLUE=''
  RESET=''
  INFO="INFO:"
  SUCCESS="SUCCESS:"
  WARNING="WARNING:"
  ERROR="ERROR:"
fi

# Default values
WARNING_DAYS=30
DAYS_ONLY=false
USE_COLOR=true
PORT=443
DEBUG=false

# Function to display usage information
show_help() {
  grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# \?//'
  exit 0
}

# Function to display error message and exit
error() {
  if $USE_COLOR; then
    printf "%s%s %s%s\n" "${RED}" "${ERROR}" "$1" "${RESET}" >&2
  else
    printf "%s %s\n" "${ERROR}" "$1" >&2
  fi
  exit 3
}

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    -d|--days-only)
      DAYS_ONLY=true
      shift
      ;;
    -w|--warning)
      if [ -z "$2" ] || ! echo "$2" | grep -q '^[0-9]\+$'; then
        error "Warning threshold must be a positive number"
      fi
      WARNING_DAYS="$2"
      shift 2
      ;;
    -c|--no-color)
      USE_COLOR=false
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

# Check if host is provided
if [ $# -lt 1 ]; then
  error "Missing host argument"
fi

HOST="$1"
# Use provided port or default
if [ $# -ge 2 ]; then
  if ! echo "$2" | grep -q '^[0-9]\+$'; then
    error "Port must be a number"
  fi
  PORT="$2"
fi

if [ "$DEBUG" = "true" ]; then
  echo "DEBUG: Host: $HOST" >&2
  echo "DEBUG: Port: $PORT" >&2
  echo "DEBUG: Warning days: $WARNING_DAYS" >&2
  echo "DEBUG: Days only: $DAYS_ONLY" >&2
fi

# Get certificate information
get_cert_info() {
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Connecting to $HOST:$PORT" >&2
  fi
  
  # Use a direct approach that works in most shells
  CERT_INFO=$(/usr/bin/openssl s_client -connect "$HOST:$PORT" -servername "$HOST" </dev/null 2>/dev/null)
  if [ -z "$CERT_INFO" ]; then
    error "Failed to connect to $HOST:$PORT"
  fi
  
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Successfully connected and received certificate" >&2
  fi
  
  # Try multiple approaches to extract dates
  # Approach 1: Direct extraction with openssl
  CERT_DATES=$(echo "$CERT_INFO" | /usr/bin/openssl x509 -noout -dates 2>/dev/null)
  
  # Approach 2: If approach 1 fails, try extracting the certificate first
  if [ -z "$CERT_DATES" ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "DEBUG: First approach failed, trying to extract certificate first" >&2
    fi
    
    CERT=$(echo "$CERT_INFO" | sed -n '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')
    if [ -n "$CERT" ]; then
      CERT_DATES=$(echo "$CERT" | openssl x509 -noout -dates 2>/dev/null)
    fi
  fi
  
  # Approach 3: Use grep to find dates directly
  if [ -z "$CERT_DATES" ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "DEBUG: Second approach failed, trying direct grep" >&2
    fi
    
    CERT_DATES=$(echo "$CERT_INFO" | grep -E "notBefore=|notAfter=")
  fi
  
  # If all approaches fail
  if [ -z "$CERT_DATES" ]; then
    error "Failed to extract certificate dates"
  fi
  
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Successfully extracted dates: $CERT_DATES" >&2
  fi
  
  echo "$CERT_DATES"
}

# Calculate days until expiration
calculate_days_until_expiry() {
  # Extract the notAfter date
  not_after=$(echo "$1" | grep 'notAfter=' | cut -d= -f2)
  
  if [ -z "$not_after" ]; then
    # Try alternative methods to extract the date
    not_after=$(echo "$1" | grep -A 1 'Not After' | tail -n 1 | xargs)
    
    if [ -z "$not_after" ]; then
      # One more attempt with a different pattern
      not_after=$(echo "$1" | grep 'notAfter' | sed 's/.*notAfter=//')
      
      if [ -z "$not_after" ]; then
        error "Failed to extract expiration date"
      fi
    fi
  fi
  
  # Debug: Show the extracted date
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Extracted date: '$not_after'" >&2
  fi
  
  # Convert to seconds since epoch
  expire_epoch=""
  
  # Try to detect OS for date command compatibility
  os_type=$(uname -s)
  
  if [ "$os_type" = "Darwin" ]; then
    # macOS date command - try multiple formats
    expire_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null)
    if [ -z "$expire_epoch" ]; then
      expire_epoch=$(date -j -f "%b  %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null)
    fi
    if [ -z "$expire_epoch" ]; then
      # Try with explicit format for single-digit days
      day=$(echo "$not_after" | awk '{print $2}')
      rest=$(echo "$not_after" | cut -d' ' -f1,3-)
      not_after_fixed=$(echo "$rest" | sed "s/ / $day /")
      expire_epoch=$(date -j -f "%b %e %H:%M:%S %Y %Z" "$not_after_fixed" +%s 2>/dev/null)
    fi
  else
    # Linux date command
    expire_epoch=$(date -d "$not_after" +%s 2>/dev/null)
    
    # If that fails, try GNU date with explicit format
    if [ -z "$expire_epoch" ]; then
      month=$(echo "$not_after" | awk '{print $1}')
      day=$(echo "$not_after" | awk '{print $2}')
      time=$(echo "$not_after" | awk '{print $3}')
      year=$(echo "$not_after" | awk '{print $4}')
      zone=$(echo "$not_after" | awk '{print $5}')
      
      # Use zone in formatted date if available
      if [ -n "$zone" ]; then
        formatted_date="$year-$(date -d "1 $month" +%m)-$day $time $zone"
      else
        formatted_date="$year-$(date -d "1 $month" +%m)-$day $time"
      fi
      expire_epoch=$(date -d "$formatted_date" +%s 2>/dev/null)
    fi
  fi
  
  if [ -z "$expire_epoch" ]; then
    if [ "$DEBUG" = "true" ]; then
      echo "DEBUG: Failed to parse date with standard methods" >&2
      echo "DEBUG: OS type: $os_type" >&2
      echo "DEBUG: Date string: '$not_after'" >&2
    fi
    
    # Last resort: Use Python if available
    if command -v python3 >/dev/null 2>&1; then
      if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Trying Python for date parsing" >&2
      fi
      
      expire_epoch=$(python3 -c "
import sys
from datetime import datetime
import time
try:
    # Try multiple date formats
    formats = [
        '%b %d %H:%M:%S %Y %Z',
        '%b  %d %H:%M:%S %Y %Z',
        '%b %d %H:%M:%S %Y',
        '%Y-%m-%d %H:%M:%S'
    ]
    
    date_str = '$not_after'
    parsed = None
    
    for fmt in formats:
        try:
            parsed = datetime.strptime(date_str, fmt)
            break
        except ValueError:
            continue
    
    if parsed is None:
        # Try to handle month name and restructure
        months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 
                 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12}
        parts = date_str.split()
        if len(parts) >= 4 and parts[0] in months:
            month = months[parts[0]]
            day = int(parts[1])
            time_parts = parts[2].split(':')
            hour, minute, second = map(int, time_parts)
            year = int(parts[3])
            parsed = datetime(year, month, day, hour, minute, second)
    
    if parsed:
        print(int(parsed.timestamp()))
    else:
        sys.exit(1)
except Exception as e:
    sys.exit(1)
" 2>/dev/null)
    fi
  fi
  
  if [ -z "$expire_epoch" ]; then
    error "Failed to parse expiration date: '$not_after'"
  fi
  
  current_epoch=$(date +%s)
  
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Current epoch: $current_epoch" >&2
    echo "DEBUG: Expiry epoch: $expire_epoch" >&2
  fi
  
  days_left=$(( (expire_epoch - current_epoch) / 86400 ))
  echo "$days_left"
}

# Main execution
CERT_DATES=$(get_cert_info)
DAYS_LEFT=$(calculate_days_until_expiry "$CERT_DATES")

# Ensure DAYS_LEFT is a valid integer
if ! echo "$DAYS_LEFT" | grep -q '^-\?[0-9]\+$'; then
  if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: DAYS_LEFT is not a valid integer: '$DAYS_LEFT'" >&2
  fi
  # Set a default value
  DAYS_LEFT=0
fi

# Display results
if [ "$DAYS_ONLY" = "true" ]; then
  echo "$DAYS_LEFT"
  if [ "$DAYS_LEFT" -lt 0 ]; then
    exit 2
  elif [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    exit 1
  else
    exit 0
  fi
fi

# Format dates for display
NOT_BEFORE=$(echo "$CERT_DATES" | grep 'notBefore=' | cut -d= -f2)
NOT_AFTER=$(echo "$CERT_DATES" | grep 'notAfter=' | cut -d= -f2)

# Display full information with appropriate colors
if [ "$USE_COLOR" = "true" ]; then
  printf "${BLUE}${INFO} Host:${RESET} %s:%s\n" "$HOST" "$PORT"
  printf "${BLUE}${INFO} Valid from:${RESET} %s\n" "$NOT_BEFORE"
  printf "${BLUE}${INFO} Valid until:${RESET} %s\n" "$NOT_AFTER"
  
  if [ "$DAYS_LEFT" -lt 0 ]; then
    # Remove negative sign for display
    DAYS_EXPIRED=$(echo "$DAYS_LEFT" | sed 's/^-//')
    printf "${RED}${ERROR} EXPIRED: Certificate expired %s days ago!${RESET}\n" "$DAYS_EXPIRED"
    exit 2
  elif [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    printf "${YELLOW}${WARNING} Certificate will expire in %s days!${RESET}\n" "$DAYS_LEFT"
    exit 1
  else
    printf "${GREEN}${SUCCESS} Certificate is valid for %s more days.${RESET}\n" "$DAYS_LEFT"
    exit 0
  fi
else
  printf "Host: %s:%s\n" "$HOST" "$PORT"
  printf "Valid from: %s\n" "$NOT_BEFORE"
  printf "Valid until: %s\n" "$NOT_AFTER"
  
  if [ "$DAYS_LEFT" -lt 0 ]; then
    # Remove negative sign for display
    DAYS_EXPIRED=$(echo "$DAYS_LEFT" | sed 's/^-//')
    printf "%s EXPIRED: Certificate expired %s days ago!\n" "$ERROR" "$DAYS_EXPIRED"
    exit 2
  elif [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    printf "%s Certificate will expire in %s days!\n" "$WARNING" "$DAYS_LEFT"
    exit 1
  else
    printf "%s Certificate is valid for %s more days.\n" "$SUCCESS" "$DAYS_LEFT"
    exit 0
  fi
fi
