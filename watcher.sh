#!/usr/bin/env bash

if ! command -v inotifywait &> /dev/null; then
    echo "inotify-tools are not installed. Please install and try again."
    exit 1
fi

# Parse arguments
watch_dir="$1"
prefix="$2"

if [[ -z "$watch_dir" ]]; then
    echo "Usage: $0 /path/to/watch [optional-prefix]"
    exit 1
fi

# Function to get the next counter value
get_next_counter() {
    highest=$(find "$watch_dir" -maxdepth 1 -type f -regex ".*/[0-9]+\..*" \
        | sed -E 's/.*\/([0-9]+)\..*/\1/' \
        | sort -n \
        | tail -n 1)

    if [[ -z "$highest" ]]; then
        echo 0
    else
        echo $((highest + 1))
    fi
}

# Check if the folder is empty of real files
folder_is_effectively_empty() {
    shopt -s nullglob
    files=("$watch_dir"/*)
    for f in "${files[@]}"; do
        base="$(basename "$f")"
        if [[ "$base" != .* && "$base" != *.tmp && "$base" != *.part && "$base" != *.crdownload ]]; then
            return 1  # Found real file
        fi
    done
    return 0  # Folder is effectively empty
}

# Initialize
counter=$(get_next_counter)
was_empty=0
echo "Starting counter at $counter"
[[ -n "$prefix" ]] && echo "Using prefix: '$prefix'"

# Start monitoring
inotifywait -m -e close_write -e delete -e moved_from --format "%e %f" "$watch_dir" | while read -r event FILE; do
    if [[ "$FILE" == *.part || "$FILE" == *.crdownload || "$FILE" == *.tmp ]]; then
        continue
    fi

    if [[ "$event" == *"DELETE"* || "$event" == *"MOVED_FROM"* ]]; then
        if folder_is_effectively_empty; then
            if [[ "$was_empty" -eq 0 ]]; then
                counter=0
                was_empty=1
                echo "All relevant files deleted or moved. Counter reset to 0."
            fi
        else
            was_empty=0
        fi
        continue
    fi

    # A file is added or changed
    was_empty=0  # Reset flag since folder is not empty anymore

    new_name="${prefix:+$prefix-}${counter}"

    sleep 1
    if [[ "$FILE" == *.* ]]; then
        EXT="${FILE##*.}"
        mv "$watch_dir/$FILE" "$watch_dir/$new_name.$EXT"
        echo "Renamed $FILE → $new_name.$EXT"
    else
        mv "$watch_dir/$FILE" "$watch_dir/$new_name"
        echo "Renamed $FILE → $new_name"
    fi

    counter=$((counter + 1))
done
