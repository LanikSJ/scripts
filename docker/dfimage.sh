#!/usr/bin/env bash

# Define the Docker image to use
DFIMAGE_IMAGE="ghcr.io/laniksj/dfimage"

# Function to display usage information
usage() {
  echo "Usage: $0 <image_name_or_id>"
  echo "  Runs the dfimage tool to analyze a Docker image."
  echo "  Example: $0 my-image:latest"
  exit 1
}

# Check if docker command is available
if ! command -v docker &> /dev/null; then
  echo "Error: docker command not found. Please install Docker."
  exit 1
fi

# Check if an argument is provided
if [ -z "$1" ]; then
  usage
fi

# Run the dfimage Docker container
docker run -v /var/run/docker.sock:/var/run/docker.sock --rm "${DFIMAGE_IMAGE}" "$1"
