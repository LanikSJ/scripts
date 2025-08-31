#!/bin/bash
# WAV → MP3 converter (320 kbps) with progress bar + batch mode
# - Converts single file or entire folder
# - Clean logging
# - Optional progress bar (pv)
# - Parallel conversion if GNU parallel is available
# - Options: --skip-existing (don’t overwrite), --overwrite (force re-convert)

set -e

MODE="overwrite"   # default mode
TARGET=""          # file or folder

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
            TARGET="$arg"
            shift
            ;;
    esac
done

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <input.wav | folder> [--skip-existing | --overwrite]"
    exit 1
fi

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

if [ -f "$TARGET" ]; then
    # Single file
    convert_one "$TARGET"
elif [ -d "$TARGET" ]; then
    # Batch mode
    shopt -s nullglob nocaseglob
    FILES=("$TARGET"/*.wav "$TARGET"/*.WAV)
    shopt -u nocaseglob

    if [ ${#FILES[@]} -eq 0 ]; then
        echo "⚠️ No WAV files found in $TARGET"
        exit 0
    fi

    TOTAL=${#FILES[@]}
    echo "📂 Found $TOTAL WAV file(s) in $TARGET"

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
    echo "🎉 All done! Converted $TOTAL file(s)."
else
    echo "❌ Error: $TARGET is not a file or folder"
    exit 1
fi

