#!/usr/bin/env bash
# HELP_START
# Script to retrieve SSL certificates from remote hosts
#
# Usage: get-cert.sh [options] hostname [port]
#
# Options:
#   -h, --help              Display this help message
#   -o, --output FILE       Save certificate to a file
#   -f, --format FORMAT     Output format (pem, der, text) [default: pem]
#   -t, --timeout SECONDS   Connection timeout in seconds [default: 5]
#   -v, --verbose           Enable verbose output
#
# Examples:
#   get-cert.sh example.com
#   get-cert.sh -o cert.pem example.com 443
#   get-cert.sh -f text -v example.com
# HELP_END
#

set -e

# Default values
FORMAT="pem"
TIMEOUT=5
VERBOSE=false
OUTPUT_FILE=""

# Function to display usage information
show_help() {
  sed -n '/^# HELP_START/,/^# HELP_END/p' "$0" | grep -v 'HELP_\(START\|END\)' | sed 's/^# *//'
  exit 0
}

# Function to display error message and exit
error() {
  echo "ERROR: $1" >&2
  exit 1
}

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help
      ;;
    -o|--output)
      if [ -z "$2" ]; then
        error "Output file name is required"
      fi
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -f|--format)
      if [ -z "$2" ]; then
        error "Format is required"
      fi
      case "$2" in
        pem|der|text)
          FORMAT="$2"
          ;;
        *)
          error "Invalid format: $2. Valid formats are: pem, der, text"
          ;;
      esac
      shift 2
      ;;
    -t|--timeout)
      if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        error "Timeout must be a positive number"
      fi
      TIMEOUT="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
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

# Check if hostname is provided
if [ $# -lt 1 ]; then
  error "Missing hostname argument"
fi

REMHOST="$1"
# Use provided port or default
REMPORT="${2:-443}"

if ! [[ "$REMPORT" =~ ^[0-9]+$ ]]; then
  error "Port must be a number"
fi

# Display connection information if verbose
if $VERBOSE; then
  echo "Connecting to $REMHOST:$REMPORT..."
fi

# Build OpenSSL command with options
OPENSSL_CMD="/usr/bin/openssl s_client -connect ${REMHOST}:${REMPORT} -servername ${REMHOST}"

# Get the certificate with timeout
if $VERBOSE; then
  echo "Using timeout of ${TIMEOUT} seconds..."
fi

# Create a temporary file for the certificate data
TEMP_OUTPUT=$(mktemp)

# Use timeout command if available
if command -v timeout >/dev/null 2>&1; then
  # Run the command in background and kill it after timeout
  (echo | $OPENSSL_CMD > "$TEMP_OUTPUT" 2>&1) & 
  PID=$!
  
  # Wait for the specified timeout
  TIMER=0
  while [ $TIMER -lt "$TIMEOUT" ] && kill -0 $PID 2>/dev/null; do
    sleep 1
    TIMER=$((TIMER + 1))
  done
  
  # Check if the process is still running
  if kill -0 $PID 2>/dev/null; then
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
    error "Connection to $REMHOST:$REMPORT timed out after ${TIMEOUT} seconds"
  fi
  
  # Read the output
  CERT_DATA=$(cat "$TEMP_OUTPUT")
else
  # Fallback if timeout command is not available
  CERT_DATA=$(echo | $OPENSSL_CMD 2>&1)
fi

# Clean up
rm -f "$TEMP_OUTPUT"

# Check if the certificate retrieval was successful
if echo "$CERT_DATA" | grep -q "connect:errno="; then
  if $VERBOSE; then
    ERROR_MSG=$(echo "$CERT_DATA" | grep -o "connect:errno=[0-9]*" | head -1)
    if [ -n "$ERROR_MSG" ]; then
      error "Failed to connect to $REMHOST:$REMPORT - $ERROR_MSG"
    else
      error "Failed to connect to $REMHOST:$REMPORT - Connection failed"
    fi
  else
    error "Failed to connect to $REMHOST:$REMPORT"
  fi
fi

# Extract the certificate
CERT=$(echo "$CERT_DATA" | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')

if [ -z "$CERT" ]; then
  error "No certificate found"
fi

# Process the certificate based on format
case "$FORMAT" in
  pem)
    RESULT="$CERT"
    ;;
  der)
    # Create a temporary file for conversion
    TEMP_PEM=$(mktemp)
    echo "$CERT" > "$TEMP_PEM"
    RESULT=$(/usr/bin/openssl x509 -in "$TEMP_PEM" -outform DER | base64)
    rm "$TEMP_PEM"
    ;;
  text)
    # Create a temporary file for conversion
    TEMP_PEM=$(mktemp)
    echo "$CERT" > "$TEMP_PEM"
    RESULT=$(/usr/bin/openssl x509 -in "$TEMP_PEM" -text -noout)
    rm "$TEMP_PEM"
    ;;
esac

# Output the result
if [ -n "$OUTPUT_FILE" ]; then
  echo "$RESULT" > "$OUTPUT_FILE"
  if $VERBOSE; then
    echo "Certificate saved to $OUTPUT_FILE"
  fi
else
  echo "$RESULT"
fi

exit 0
