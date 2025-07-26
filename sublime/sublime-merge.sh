#!/usr/bin/env bash

cd "/Applications/Sublime Merge.app/Contents/MacOS/" || echo "Sublime Merge Not Found!" && exit
[[ $(md5 sublime_merge |awk '{print $NF}') == "186FDA87C023C6270F4FFB4B55F7CA40" ]] || echo "App Hash Doesn't Match!" && exit
echo 01478BF8: 20 23 80 D2 C0 03 5F D6 | xxd -r - sublime_merge
echo 0147AB48: 1F 20 03 D5             | xxd -r - sublime_merge
echo 0147AB5C: 1F 20 03 D5             | xxd -r - sublime_merge
echo 01479964: C0 03 5F D6             | xxd -r - sublime_merge
echo 01478950: C0 03 5F D6             | xxd -r - sublime_merge
echo 0147839C: C0 03 5F D6             | xxd -r - sublime_merge

codesign --force --deep --sign - "/Applications/Sublime Merge.app"
