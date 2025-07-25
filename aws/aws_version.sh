#!/usr/bin/env bash
# Display AWS CLI Version
# Usage: aws_version.sh

aws --version | awk '{print $1}' | awk -F/ '{print $2}'
