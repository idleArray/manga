#!/bin/bash

# Check for ImageMagick
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is not installed. Please install it and try again."
    exit 1
fi

if [[ "$target" = "." ]]; then
  target="$PWD"
fi

# Check if argument is a valid directory
target="$1"
if [[ ! -d "$target" ]]; then
    echo "Error: $target is not a directory"
    exit 1
fi

# Set up progress info with sorted files
mapfile -t files < <(find "$target" -type f \( -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \) | sort)
convertible_files=()
for f in "${files[@]}"; do
    out="${f%.*}.png"
    if [[ ! -f "$out" ]]; then
        convertible_files+=("$f")
    fi
done
total_files="${#files[@]}"
progress_number=1

for f in "${files[@]}"; do
    out="${f%.*}.png"
    if [ ! -f "$out" ]; then
        echo "${progress_number}/${total_files}     ${f##*/} -> ${out##*/}"
        convert "$f" "$out"
        rm -f "$f"
    fi
    ((progress_number++))
done
