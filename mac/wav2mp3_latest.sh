#!/bin/bash
# Convert all WAVs in the latest folder in ~/Teddy/ (or ~/Teddy/ itself if no subfolders) to MP3 (320 kbps)
# Features:
# - Clean logs
# - Optional progress bar (pv)
# - --skip-existing / --overwrite
# - Parallel conversion if GNU parallel is available
# - Recursive search for WAV files

set -e

MODE="overwrite"   # default mode

# Parse args
for arg in "$@"; do
    case $arg in
        --skip-existing)
            MODE="skip"
            shift
            ;;
        --overwrite)
            MODE="overwrite"
            shift
            ;;
        *)
            echo "Usage: $0 [--skip-existing | --overwrite]"
            exit 1
            ;;
    esac
done

# Find latest folder in ~/Teddy/
LATEST_DIR=$(find ~/Teddy/ -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)
if [ -z "$LATEST_DIR" ]; then
    echo "⚠️ No subfolders found in ~/Teddy/, using ~/Teddy/ itself"
    LATEST_DIR="$HOME/Teddy"
fi

echo "📂 Target folder: $LATEST_DIR"

convert_one() {
    FILE="$1"
    BASENAME="${FILE%.*}"
    OUTPUT="${BASENAME}.mp3"

    if [ "$MODE" = "skip" ] && [ -f "$OUTPUT" ]; then
        echo "⏩ Skipping: $(basename "$OUTPUT") already exists"
        return 0
    fi

    echo "🎵 Converting: $(basename "$FILE") → $(basename "$OUTPUT")"

    if command -v pv >/dev/null 2>&1; then
        DURATION=$(ffprobe -i "$FILE" -show_entries format=duration -v quiet -of csv="p=0")
        SIZE_EST=$(printf "%.0f" "$(echo "$DURATION * 320000 / 8" | bc -l)")
        ffmpeg -hide_banner -loglevel error -y -i "$FILE" -codec:a libmp3lame -b:a 320k -f mp3 - | \
            pv -s "$SIZE_EST" > "$OUTPUT"
    else
        ffmpeg -hide_banner -loglevel error -y -i "$FILE" -codec:a libmp3lame -b:a 320k "$OUTPUT"
    fi

    echo "✅ Done: $(basename "$OUTPUT")"
}

export -f convert_one
export MODE

# Recursive search for all WAV files
FILES=()
while IFS= read -r -d '' file; do
    FILES+=("$file")
done < <(find "$LATEST_DIR" -type f \( -iname "*.wav" \) -print0)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "⚠️ No WAV files found in $LATEST_DIR"
    exit 0
fi

TOTAL=${#FILES[@]}
echo "📂 Found $TOTAL WAV file(s) in $LATEST_DIR (including subfolders)"

if command -v parallel >/dev/null 2>&1; then
    echo "⚡ Using GNU parallel for faster conversion..."
    parallel --bar convert_one ::: "${FILES[@]}"
else
    echo "➡️  Converting sequentially (install GNU parallel for speed-up)"
    for FILE in "${FILES[@]}"; do
        convert_one "$FILE"
    done
fi

echo ""
echo "🎉 All done! Converted $TOTAL file(s) in $LATEST_DIR."

