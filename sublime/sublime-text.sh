#!/usr/bin/env bash

cd "/Applications/Sublime Text.app/Contents/MacOS/" || echo "Sublime Text Not Found" && exit
[[ $(md5 -q sublime_text) == "70909b4bccb3209c6f6c80122171ba84" ]] || echo "App Hash Doesn't Match" && exit
echo 01055A38: E0 03 1F AA C0 03 5F D6 | xxd -r - sublime_text
echo 00FE4E80: 1F 20 03 D5             | xxd -r - sublime_text
echo 00FE4E94: 1F 20 03 D5             | xxd -r - sublime_text
echo 01056D2C: C0 03 5F D6             | xxd -r - sublime_text
echo 010556A0: C0 03 5F D6             | xxd -r - sublime_text
echo 00FE04C0: C0 03 5F D6             | xxd -r - sublime_text

codesign --force --deep --sign - "/Applications/Sublime Text.app"
