#!/usr/bin/env bash
# Enhanced Mac Hardware Information Script
# Determines type, speed, and additional details of the processor(s) on a Mac

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for better output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to print colored output with icons
print_header() {
    echo -e "${BLUE}🔧 === $1 ===${NC}"
}

print_info() {
    echo -e "${GREEN}📊 $1:${NC} $2"
}

print_warning() {
    echo -e "${YELLOW}⚠️  Warning:${NC} $1" >&2
}

print_error() {
    echo -e "${RED}❌ Error:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
}

# Function to safely execute commands with error handling
safe_execute() {
    local cmd="$1"
    local description="$2"
    
    if ! command -v "${cmd%% *}" &> /dev/null; then
        print_warning "Command '${cmd%% *}' not found. Skipping $description."
        return 1
    fi
    
    if ! eval "$cmd" 2>/dev/null; then
        print_warning "Failed to execute: $description"
        return 1
    fi
}

# Function to get CPU information using multiple methods
get_cpu_info() {
    print_header "CPU Information"
    
    # Method 1: sysctl for CPU brand string
    if cpu_brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null); then
        print_info "Processor" "$cpu_brand"
    else
        print_warning "Could not retrieve CPU brand string"
    fi
    
    # Method 2: Additional CPU details from sysctl
    if cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null); then
        print_info "Total CPU Cores" "$cpu_cores"
    fi
    
    if cpu_physical_cores=$(sysctl -n hw.physicalcpu 2>/dev/null); then
        print_info "Physical CPU Cores" "$cpu_physical_cores"
    fi
    
    if cpu_logical_cores=$(sysctl -n hw.logicalcpu 2>/dev/null); then
        print_info "Logical CPU Cores" "$cpu_logical_cores"
    fi
    
    # CPU frequency information
    if cpu_freq=$(sysctl -n hw.cpufrequency_max 2>/dev/null); then
        cpu_freq_ghz=$(echo "scale=2; $cpu_freq / 1000000000" | bc 2>/dev/null || echo "N/A")
        if [[ "$cpu_freq_ghz" != "N/A" ]]; then
            print_info "Max CPU Frequency" "${cpu_freq_ghz} GHz"
        fi
    fi
    
    # Cache information
    if l1_cache=$(sysctl -n hw.l1icachesize 2>/dev/null); then
        l1_cache_kb=$((l1_cache / 1024))
        print_info "L1 Instruction Cache" "${l1_cache_kb} KB"
    fi
    
    if l1_data_cache=$(sysctl -n hw.l1dcachesize 2>/dev/null); then
        l1_data_cache_kb=$((l1_data_cache / 1024))
        print_info "L1 Data Cache" "${l1_data_cache_kb} KB"
    fi
    
    if l2_cache=$(sysctl -n hw.l2cachesize 2>/dev/null); then
        l2_cache_kb=$((l2_cache / 1024))
        print_info "L2 Cache" "${l2_cache_kb} KB"
    fi
    
    if l3_cache=$(sysctl -n hw.l3cachesize 2>/dev/null); then
        l3_cache_mb=$((l3_cache / 1048576))
        print_info "L3 Cache" "${l3_cache_mb} MB"
    fi
    
    echo
}

# Function to get system profiler hardware information
get_system_profiler_info() {
    print_header "Detailed Hardware Information"
    
    if safe_execute "system_profiler SPHardwareDataType" "system profiler hardware data"; then
        echo
    else
        print_error "Failed to retrieve system profiler information"
    fi
}

# Function to get memory information
get_memory_info() {
    print_header "Memory Information"
    
    if total_memory=$(sysctl -n hw.memsize 2>/dev/null); then
        memory_gb=$(echo "scale=2; $total_memory / 1073741824" | bc 2>/dev/null || echo "N/A")
        if [[ "$memory_gb" != "N/A" ]]; then
            print_info "Total Memory" "${memory_gb} GB"
        fi
    fi
    
    echo
}

# Function to clean up log files
cleanup_logs() {
    local script_dir
    script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local log_patterns=("*.log" "*.tmp" "*hwinfo*.log" "system_profiler*.log")
    local cleaned_files=0
    
    for pattern in "${log_patterns[@]}"; do
        # Use find to locate and remove matching files
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]]; then
                rm -f "$file" 2>/dev/null && ((cleaned_files++))
            fi
        done < <(find "$script_dir" -maxdepth 1 -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    # Also clean up any temporary files in /tmp related to this script
    local temp_patterns=("/tmp/hwinfo_*" "/tmp/system_profiler_*")
    for pattern in "${temp_patterns[@]}"; do
        # Use find for /tmp cleanup to avoid globbing issues
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]]; then
                rm -f "$file" 2>/dev/null && ((cleaned_files++))
            fi
        done < <(find /tmp -maxdepth 1 -name "$(basename "$pattern")" -type f -print0 2>/dev/null)
    done
    
    if [[ $cleaned_files -gt 0 ]]; then
        print_success "Cleaned up $cleaned_files log file(s)"
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

🖥️  Enhanced Mac Hardware Information Script

OPTIONS:
    -h, --help         Show this help message
    -c, --cpu-only     Show only CPU information
    -m, --mem-only     Show only memory information
    -s, --sys-only     Show only system profiler output
    -q, --quiet        Suppress colored output
    --no-clean-logs    Skip automatic log file cleanup (cleanup is enabled by default)

Examples:
    $(basename "$0")              # Show all hardware information and clean up logs
    $(basename "$0") --cpu-only   # Show only CPU information and clean up logs
    $(basename "$0") -q           # Show information without colors and clean up logs
    $(basename "$0") --no-clean-logs # Show info but skip log cleanup

EOF
}

# Main function
main() {
    local show_cpu=true
    local show_memory=true
    local show_system=true
    local use_colors=true
    local clean_logs=true  # Default to true - cleanup enabled by default
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--cpu-only)
                show_memory=false
                show_system=false
                shift
                ;;
            -m|--mem-only)
                show_cpu=false
                show_system=false
                shift
                ;;
            -s|--sys-only)
                show_cpu=false
                show_memory=false
                shift
                ;;
            -q|--quiet)
                use_colors=false
                shift
                ;;
            --no-clean-logs)
                clean_logs=false
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Disable colors if requested
    if [[ "$use_colors" == false ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    fi
    
    # Check if running on macOS
    check_macos
    
    # Check for required commands
    if ! command -v bc &> /dev/null; then
        print_warning "bc command not found. Some calculations may not work properly."
    fi
    
    echo -e "${BLUE}🖥️  Mac Hardware Information${NC}"
    echo "📅 Generated on: $(date)"
    echo
    
    # Execute requested information gathering
    [[ "$show_cpu" == true ]] && get_cpu_info
    [[ "$show_memory" == true ]] && get_memory_info
    [[ "$show_system" == true ]] && get_system_profiler_info
    
    # Clean up log files if requested or if script completed successfully
    if [[ "$clean_logs" == true ]]; then
        echo
        cleanup_logs
    fi
    
    # Script completed successfully
    echo
    print_success "Hardware information gathering completed successfully!"
}

# Execute main function with all arguments
main "$@"
