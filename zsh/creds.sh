#!/usr/bin/env bash
# Script to add credentials to macOS Keychain

security add-generic-password -s "Homebrew" -a "GitHub_API_Token" -w "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
security add-generic-password -s "IPInfo" -a "Token" -w "abcdefghijklmnopqrstuvwxyz1234567890"
security add-generic-password -s "Bitwarden" -a "Session" -w "abcdefghijklmnopqrstuvwxyz1234567890"
