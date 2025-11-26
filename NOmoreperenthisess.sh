#!/bin/bash

# Check if folder path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/folder"
  exit 1
fi

TARGET_DIR="$1"

# Ensure it's a valid directory
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a valid directory."
  exit 1
fi

# Loop through subdirectories
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r DIR; do
  BASENAME=$(basename "$DIR")

  # Clean the name: remove text inside {}, (), and [] including brackets
  CLEAN_NAME=$(echo "$BASENAME" | sed -E 's/(\[[^]]*\]|\([^)]*\)|\{[^}]*\})//g' | xargs)

  # Only rename if the name actually changes
  if [ "$CLEAN_NAME" != "$BASENAME" ]; then
    NEW_PATH="$(dirname "$DIR")/$CLEAN_NAME"

    # Check if the target name already exists
    if [ -e "$NEW_PATH" ]; then
      echo "Skipping '$DIR' -> '$NEW_PATH': Target already exists."
    else
      echo "Renaming '$DIR' -> '$NEW_PATH'"
      mv "$DIR" "$NEW_PATH"
    fi
  fi
done
