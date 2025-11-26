#!/bin/bash

# Check if img2pdf is installed
if ! command -v img2pdf &> /dev/null; then
  echo "img2pdf is not installed. Please install it and try again."
  exit 1
fi

# Check arguments
input_folder="$1"
output_folder="$2"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 input_folder [output_folder]"
  exit 1
fi

# Expand ~ if used
input_folder="${input_folder/#\~/$HOME}"
output_folder="${output_folder/#\~/$HOME}"

# Validate input folder
if [ ! -d "$input_folder" ]; then
  echo "Input folder '$input_folder' not found."
  exit 1
fi

# If output folder provided, check it exists
if [ -n "$output_folder" ]; then
  if [ ! -d "$output_folder" ]; then
    echo "Output folder '$output_folder' not found."
    exit 1
  fi
  [[ "${output_folder}" != */ ]] && output_folder="${output_folder}/"
fi

# Loop over all subdirectories
find "$input_folder" -type d -print0 | sort -z | while IFS= read -r -d '' subfolder; do
  mapfile -t img_files < <(
    find "$subfolder" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort -V
  )

  if [ ${#img_files[@]} -eq 0 ]; then
    continue
  fi

  subfolder_name=$(basename "$subfolder")
  if [ -n "$output_folder" ]; then
    output_file="${output_folder}${subfolder_name}.pdf"
  else
    output_file="${subfolder}/${subfolder_name}.pdf"
  fi  

  echo "📂 Creating PDF for folder: $subfolder_name"

  final_images=()

  for img in "${img_files[@]}"; do
    identify_output=$(identify "$img" 2>/dev/null)
    if [[ -z "$identify_output" ]]; then
      echo "  ⚠️ Skipping unreadable image: $(basename "$img")"
      continue
    fi

    read w h < <(identify -format "%w %h" "$img")
    dpi=$(identify -format "%x x %y" "$img" | sed 's/ PixelsPerInch//g')

    echo "  🖼️ $(basename "$img") — Size: ${w}x${h} — DPI: $dpi"

    if (( w < 10 || h < 10 )); then
      echo "  ⚠️ Skipping tiny image: $(basename "$img") (${w}x${h})"
      continue
    fi

    if [[ "$img" == *.png ]]; then
      if img2pdf "$img" -o /dev/null 2>/dev/null; then
        final_images+=("$img")
      else
        fixed_img="${img%.*}_fixed.png"
        echo "  🔧 Fixing PNG: $(basename "$img")"
        convert "$img" -units PixelsPerInch -density 300 -alpha off "$fixed_img"
        final_images+=("$fixed_img")
      fi
    else
      final_images+=("$img")
    fi
  done

  if [ ${#final_images[@]} -eq 0 ]; then
    echo "  ⚠️ No valid images after processing. Skipping."
    continue
  fi

  if img2pdf "${final_images[@]}" -o "$output_file"; then
    echo "  ✅ Created: $output_file"
  else
    echo "  ❌ Failed to create PDF for folder: $subfolder_name"
  fi

  # Clean up any temporary fixed PNGs
  for img in "${final_images[@]}"; do
    [[ "$img" == *_fixed.png ]] && rm -f "$img"
  done

done
exit 0