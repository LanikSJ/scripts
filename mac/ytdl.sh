#!/usr/bin/env bash
# shellcheck disable=SC2088

yt-dlp --ignore-config --continue --console-title --no-warnings --user-agent "Mozilla/5.0 Gecko/20100101" \
	--no-check-certificate --youtube-skip-dash-manifest --yes-playlist --ignore-errors --format bestaudio/best \
	--extract-audio --audio-format "mp3" --audio-quality 0 --embed-thumbnail --output '~/Downloads/%(title)s.%(ext)s' "$1"
