#!/usr/bin/env python3
"""
Script to rename Ring doorbell video files from the format
Ring_YYYYMMDD_HHMM_UUID.mp4 to RingVideo_YYYYMMDD_HHMM.mp4.
"""

import os
import re
import sys
from collections import defaultdict

# Terminal colors and icons
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

class Icons:
    INFO = 'ℹ'
    SUCCESS = '✓'
    WARNING = '⚠'
    ERROR = '✗'


def rename_ring_files(folder):
    """
    Rename Ring video files in the specified folder.

    Args:
        folder (str): Path to the folder containing Ring video files

    Returns:
        int: Number of files renamed
    """
    pattern = re.compile(
        r'^Ring_(\d{8}_\d{4})_'
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.mp4$'
    )

    if not os.path.isdir(folder):
        print(f"{Colors.RED}{Icons.ERROR} Folder not found: {folder}{Colors.RESET}")
        return 0

    target_names = defaultdict(list)

    for filename in os.listdir(folder):
        if filename == '.DS_Store':
            continue
        match = pattern.match(filename)
        if match:
            timestamp = match.group(1)
            target = f"RingVideo_{timestamp}.mp4"
            target_names[target].append(filename)

    renamed_count = 0

    for target, sources in target_names.items():
        if len(sources) == 1:
            src = os.path.join(folder, sources[0])
            dst = os.path.join(folder, target)
            os.rename(src, dst)
            print(f"{Colors.GREEN}{Icons.SUCCESS} Renamed: {sources[0]} -> {target}{Colors.RESET}")
            renamed_count += 1
        else:
            for i, src_name in enumerate(sorted(sources), 1):
                src = os.path.join(folder, src_name)
                base, ext = os.path.splitext(target)
                dst_name = f"{base}_{i}{ext}"
                dst = os.path.join(folder, dst_name)
                os.rename(src, dst)
                print(f"{Colors.YELLOW}{Icons.WARNING} Renamed: {src_name} -> {dst_name}{Colors.RESET}")
                renamed_count += 1

    return renamed_count


def main():
    """Main function to parse arguments and rename Ring files."""
    import argparse
    parser = argparse.ArgumentParser(
        description='Rename Ring video files from Ring_YYYYMMDD_HHMM_UUID.mp4 to RingVideo_YYYYMMDD_HHMM.mp4'
    )
    parser.add_argument('folders', nargs='+', help='Folder(s) containing Ring video files')
    args = parser.parse_args()

    total_renamed = 0

    for folder in args.folders:
        print(f"{Colors.BLUE}{Icons.INFO} Processing: {folder}{Colors.RESET}")
        count = rename_ring_files(folder)
        total_renamed += count

    print(f"{Colors.GREEN}{Icons.SUCCESS} Done! Renamed {total_renamed} files total.{Colors.RESET}")


if __name__ == "__main__":
    main()
