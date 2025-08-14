#!/usr/bin/env bash

# YouTube Downloader Script
# Downloads audio from YouTube videos/playlists using yt-dlp
# Usage: ./ytdl.sh <URL> [OPTIONS]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Default configuration
DEFAULT_OUTPUT_DIR="$HOME/Downloads"
DEFAULT_AUDIO_FORMAT="mp3"
DEFAULT_AUDIO_QUALITY="0"  # 0 = best quality
DEFAULT_USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Icons for output
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️"
readonly ICON_INFO="ℹ️"
readonly ICON_DOWNLOAD="⬇️"
readonly ICON_MUSIC="🎵"
readonly ICON_FOLDER="📁"
readonly ICON_LINK="🔗"
readonly ICON_GEAR="⚙️"
readonly ICON_ROCKET="🚀"
readonly ICON_YOUTUBE="📺"
readonly ICON_PLAYLIST="📋"
readonly ICON_SINGLE="🎯"
readonly ICON_QUALITY="💎"
readonly ICON_FORMAT="🎛️"
readonly ICON_TOOLS="🔧"
readonly ICON_VALIDATE="🔍"
readonly ICON_CREATE="📂"
readonly ICON_EXECUTE="⚡"
readonly ICON_COMPLETE="🎉"

# Function to display usage information
usage() {
    cat << EOF
${ICON_YOUTUBE} YouTube Audio Downloader ${ICON_MUSIC}

Usage: $0 <URL> [OPTIONS]

Download audio from YouTube videos or playlists.

ARGUMENTS:
    ${ICON_LINK} URL                 YouTube video or playlist URL

OPTIONS:
    ${ICON_FOLDER} -o, --output DIR    Output directory (default: $DEFAULT_OUTPUT_DIR)
    ${ICON_FORMAT} -f, --format FMT    Audio format: mp3, m4a, wav, etc. (default: $DEFAULT_AUDIO_FORMAT)
    ${ICON_QUALITY} -q, --quality NUM   Audio quality: 0-9 (0=best, 9=worst) (default: $DEFAULT_AUDIO_QUALITY)
    ${ICON_PLAYLIST} -p, --playlist      Force playlist mode (download entire playlist)
    ${ICON_SINGLE} -s, --single        Force single video mode (download only one video from playlist)
    ${ICON_INFO} -h, --help          Show this help message

EXAMPLES:
    ${ICON_EXECUTE} $0 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    ${ICON_EXECUTE} $0 "https://www.youtube.com/playlist?list=..." --output ~/Music
    ${ICON_EXECUTE} $0 "https://youtu.be/dQw4w9WgXcQ" --format m4a --quality 2

EOF
}

# Function to log messages with colors and icons
log() {
    local level="$1"
    shift
    case "$level" in
        "INFO")     echo -e "${GREEN}${ICON_INFO} [INFO]${NC} $*" ;;
        "SUCCESS")  echo -e "${GREEN}${ICON_SUCCESS} [SUCCESS]${NC} $*" ;;
        "WARN")     echo -e "${YELLOW}${ICON_WARNING} [WARN]${NC} $*" ;;
        "ERROR")    echo -e "${RED}${ICON_ERROR} [ERROR]${NC} $*" >&2 ;;
        "DOWNLOAD") echo -e "${BLUE}${ICON_DOWNLOAD} [DOWNLOAD]${NC} $*" ;;
        "MUSIC")    echo -e "${CYAN}${ICON_MUSIC} [MUSIC]${NC} $*" ;;
        "FOLDER")   echo -e "${YELLOW}${ICON_FOLDER} [FOLDER]${NC} $*" ;;
        "LINK")     echo -e "${BLUE}${ICON_LINK} [LINK]${NC} $*" ;;
        "GEAR")     echo -e "${CYAN}${ICON_GEAR} [CONFIG]${NC} $*" ;;
        "TOOLS")    echo -e "${BLUE}${ICON_TOOLS} [TOOLS]${NC} $*" ;;
        "VALIDATE") echo -e "${YELLOW}${ICON_VALIDATE} [VALIDATE]${NC} $*" ;;
        "CREATE")   echo -e "${GREEN}${ICON_CREATE} [CREATE]${NC} $*" ;;
        "EXECUTE")  echo -e "${CYAN}${ICON_EXECUTE} [EXECUTE]${NC} $*" ;;
        "COMPLETE") echo -e "${GREEN}${ICON_COMPLETE} [COMPLETE]${NC} $*" ;;
    esac
}

# Function to check if required tools are installed
check_dependencies() {
    log "TOOLS" "Checking required dependencies..."
    local missing_deps=()
    
    if ! command -v yt-dlp &> /dev/null; then
        missing_deps+=("yt-dlp")
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        missing_deps+=("ffmpeg")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "INFO" "Install with: brew install yt-dlp ffmpeg"
        exit 1
    fi
    
    log "SUCCESS" "All dependencies are installed"
}

# Function to validate URL
validate_url() {
    local url="$1"
    
    log "VALIDATE" "Validating YouTube URL..."
    # Basic URL validation for YouTube
    if [[ ! "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.be|m\.youtube\.com) ]]; then
        log "ERROR" "Invalid YouTube URL: $url"
        log "INFO" "Please provide a valid YouTube URL"
        exit 1
    fi
    
    log "SUCCESS" "URL validation passed"
}

# Function to create output directory if it doesn't exist
ensure_output_dir() {
    local output_dir="$1"
    
    log "FOLDER" "Checking output directory: $output_dir"
    if [[ ! -d "$output_dir" ]]; then
        log "CREATE" "Creating output directory: $output_dir"
        mkdir -p "$output_dir" || {
            log "ERROR" "Failed to create output directory: $output_dir"
            exit 1
        }
        log "SUCCESS" "Output directory created successfully"
    else
        log "SUCCESS" "Output directory already exists"
    fi
}

# Function to download audio
download_audio() {
    local url="$1"
    local output_dir="$2"
    local audio_format="$3"
    local audio_quality="$4"
    local playlist_mode="$5"
    
    log "GEAR" "Configuring download parameters..."
    
    # Build yt-dlp command arguments
    local yt_dlp_args=(
        --ignore-config
        --continue
        --console-title
        --no-warnings
        --user-agent "$DEFAULT_USER_AGENT"
        --youtube-skip-dash-manifest
        --ignore-errors
        --format "bestaudio/best"
        --extract-audio
        --audio-format "$audio_format"
        --audio-quality "$audio_quality"
        --embed-thumbnail
        --add-metadata
        --output "${output_dir}/%(uploader)s - %(title)s.%(ext)s"
    )
    
    # Add playlist handling
    if [[ "$playlist_mode" == "yes" ]]; then
        yt_dlp_args+=(--yes-playlist)
        log "GEAR" "Mode: Playlist download (entire playlist)"
    elif [[ "$playlist_mode" == "no" ]]; then
        yt_dlp_args+=(--no-playlist)
        log "GEAR" "Mode: Single video download"
    else
        # Default: let yt-dlp decide based on URL
        yt_dlp_args+=(--yes-playlist)
        log "GEAR" "Mode: Auto-detect (playlist if URL contains playlist)"
    fi
    
    log "DOWNLOAD" "Starting download process..."
    log "LINK" "URL: $url"
    log "FOLDER" "Output: $output_dir"
    log "MUSIC" "Format: $audio_format (quality: $audio_quality)"
    
    # Execute yt-dlp with error handling
    log "EXECUTE" "Launching yt-dlp..."
    if yt-dlp "${yt_dlp_args[@]}" "$url"; then
        log "COMPLETE" "Download completed successfully!"
    else
        local exit_code=$?
        log "ERROR" "Download failed with exit code: $exit_code"
        exit $exit_code
    fi
}

# Main function
main() {
    # Display startup banner
    echo -e "${CYAN}${ICON_ROCKET}========================================${ICON_ROCKET}${NC}"
    echo -e "${CYAN}${ICON_YOUTUBE}  YouTube Audio Downloader v2.0  ${ICON_MUSIC}${NC}"
    echo -e "${CYAN}${ICON_ROCKET}========================================${ICON_ROCKET}${NC}"
    echo ""
    
    local url=""
    local output_dir="$DEFAULT_OUTPUT_DIR"
    local audio_format="$DEFAULT_AUDIO_FORMAT"
    local audio_quality="$DEFAULT_AUDIO_QUALITY"
    local playlist_mode="auto"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -f|--format)
                audio_format="$2"
                shift 2
                ;;
            -q|--quality)
                audio_quality="$2"
                shift 2
                ;;
            -p|--playlist)
                playlist_mode="yes"
                shift
                ;;
            -s|--single)
                playlist_mode="no"
                shift
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$url" ]]; then
                    url="$1"
                else
                    log "ERROR" "Multiple URLs not supported"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$url" ]]; then
        log "ERROR" "URL is required"
        usage
        exit 1
    fi
    
    # Validate audio quality
    if [[ ! "$audio_quality" =~ ^[0-9]$ ]]; then
        log "ERROR" "Audio quality must be a number between 0-9"
        exit 1
    fi
    
    # Run checks and download
    check_dependencies
    validate_url "$url"
    ensure_output_dir "$output_dir"
    download_audio "$url" "$output_dir" "$audio_format" "$audio_quality" "$playlist_mode"
}

# Run main function with all arguments
main "$@"
