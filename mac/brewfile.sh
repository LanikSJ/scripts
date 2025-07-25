#!/usr/bin/env bash
# This script will create a Brewfile that can be used to install all the brew packages

brew bundle dump --all --force --global --file="$HOME"/.Brewfile
echo "Done!"
