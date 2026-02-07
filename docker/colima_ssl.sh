#!/usr/bin/env bash
#
# Fix SSL certificates in Colima for common container registries
# This script fetches and installs MITM certificates needed for pulling
# images from Docker Hub and GitHub Container Registry
#

set -euo pipefail

# Configuration
CERT_DIR="/usr/local/share/ca-certificates/mitm"
REGISTRIES=(
    "registry.hub.docker.com:443"
    "ghcr.io:443"
)

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions (simplified per cline-rules)
log_warn() {
    echo -e "${YELLOW}⚠️${NC} $*" >&2
}

log_error() {
    echo -e "${RED}❌${NC} $*" >&2
}

# Show usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Fix SSL certificates in Colima for common container registries.

OPTIONS:
    -r, --registry HOST:PORT   Add a registry to fetch certificates from
    -s, --skip-restart         Skip restarting Colima after installation
    -c, --clean                Remove existing MITM certificates first
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") -c -s
    $(basename "$0") -r "registry.gitlab.com:443"

EOF
    exit 0
}

# Parse command line arguments
SKIP_RESTART=false
CLEAN_MODE=false
VERBOSE=false
EXTRA_REGISTRIES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--registry)
            EXTRA_REGISTRIES+=("$2")
            shift 2
            ;;
        -s|--skip-restart)
            SKIP_RESTART=true
            shift
            ;;
        -c|--clean)
            CLEAN_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if Colima is running
check_colima() {
    if ! colima status &>/dev/null; then
        log_error "Colima is not running. Please start Colima first."
        exit 1
    fi
    echo "✅ Colima is running"
}

# Clean up existing certificates if requested
cleanup_certificates() {
    echo "🧹 Cleaning existing MITM certificates..."
    colima ssh -- sudo rm -rf "$CERT_DIR" 2>/dev/null || true
    echo "✅ Cleanup complete"
}

# Create certificate directory
create_cert_directory() {
    echo "📁 Creating certificate directory: $CERT_DIR"
    colima ssh -- sudo mkdir -p "$CERT_DIR"
}

# Fetch certificates from a registry
fetch_certificates() {
    local registry="$1"
    local host="${registry%%:*}"
    local port="${registry##*:}"

    echo "🔐 Fetching certificates from ${registry}..."

    # Extract hostname for prefix
    local short_host
    short_host=$(echo "$host" | sed 's/\./_/g' | tr ':' '_')

    local output_file="$CERT_DIR/${short_host}.crt"

    local cmd="openssl s_client -showcerts -connect ${host}:${port} -servername ${host} < /dev/null 2>/dev/null |
        awk 'BEGIN {c=0;} /-----BEGIN CERTIFICATE/{c++; print > \"${output_file}_\" c \".crt\"}'"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "🔧 Running: $cmd"
    fi

    colima ssh -- sudo sh -c "$cmd"

    # Count extracted certificates
    local cert_count
    cert_count=$(colima ssh -- sudo sh -c "ls -1 ${output_file}_*.crt 2>/dev/null | wc -l")

    if [[ "$cert_count" -gt 0 ]]; then
        echo "✅ Fetched ${cert_count} certificate(s) from ${host}"
    else
        log_warn "No certificates fetched from ${host}"
    fi
}

# Update CA certificates in the VM
update_ca_certificates() {
    echo "🔐 Updating CA certificates in Colima VM..."
    colima ssh -- sudo update-ca-certificates --fresh 2>&1 || \
    colima ssh -- sudo update-ca-certificates

    local certs_added
    certs_added=$(colima ssh -- sudo sh -c "grep -c 'added' /etc/ca-certificates.conf" 2>/dev/null || echo "0")
    echo "✅ Updated CA certificates (${certs_added} added)"
}

# Restart Colima
restart_colima() {
    echo "🔄 Restarting Colima..."
    colima restart
    echo "✅ Colima restarted successfully"
}

# Main execution
main() {
    echo "========================================"
    echo "  Fixing Colima SSL Certificates"
    echo "========================================"
    echo

    # Check prerequisites
    check_colima

    # Optional cleanup
    if [[ "$CLEAN_MODE" == "true" ]]; then
        cleanup_certificates
    fi

    # Create directory
    create_cert_directory

    # Merge default and extra registries
    ALL_REGISTRIES=("${REGISTRIES[@]}" "${EXTRA_REGISTRIES[@]}")

    # Fetch certificates from each registry
    for registry in "${ALL_REGISTRIES[@]}"; do
        fetch_certificates "$registry"
    done

    # Update CA certificates
    update_ca_certificates

    # Optionally restart
    if [[ "$SKIP_RESTART" == "false" ]]; then
        echo
        read -p "Restart Colima to apply changes? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]?$ ]] || [[ -z $REPLY ]]; then
            restart_colima
        else
            log_warn "Skipping restart. Run 'colima restart' manually to apply changes."
        fi
    fi

    echo
    echo "========================================"
    echo "✅ Done!"
    echo "========================================"
    echo
    echo "Test with: docker pull nginx"
}

main
