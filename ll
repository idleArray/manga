#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-.}"
declare -a bad_dirs=()

# iterate ALL subdirectories, including deep ones
while IFS= read -r -d '' dir; do
  # skip the root directory itself unless you want it included
  [[ "$dir" == "$SRC_DIR" ]] && continue

  has_third=false
  nums=()

  # check all files inside this directory (only this directory, not deeper)
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"

    # pattern 1: n.ext
    if [[ $base =~ ^([0-9]+)\.([^.]+)$ ]]; then
      nums+=("${BASH_REMATCH[1]}")

    # pattern 2: prefix-n.ext
    elif [[ $base =~ ^(.+)-([0-9]+)\.([^.]+)$ ]]; then
      nums+=("${BASH_REMATCH[2]}")

    # pattern 3: anything else
    else
      has_third=true
    fi
  done < <(find "$dir" -maxdepth 1 -mindepth 1 -type f -print0)

  # third-category file → add directory
  if $has_third ; then
    bad_dirs+=("$dir")
    continue
  fi

  # no numeric files → add directory
  if (( ${#nums[@]} == 0 )); then
    bad_dirs+=("$dir")
    continue
  fi

  # unique + sorted numbers
  mapfile -t uniq_sorted < <(printf '%s\n' "${nums[@]}" | sort -n -u)
  first="${uniq_sorted[0]}"
  last="${uniq_sorted[-1]}"
  count="${#uniq_sorted[@]}"

  # numbering does not start at 0 → add to array
  if (( first != 0 )); then
    bad_dirs+=("$dir")
    continue
  fi

  # detect gaps if numbers *do* start at 0
  if (( last + 1 != count )); then
    declare -A seen=()
    for n in "${uniq_sorted[@]}"; do seen[$n]=1; done

    missing=()
    for ((i=0;i<=last;i++)); do
      [[ -z "${seen[$i]+x}" ]] && missing+=("$i")
    done

    printf 'Gap in folder: %s\nMissing numbers: %s\n\n' \
      "$dir" "$(IFS=,; echo "${missing[*]}")"
  fi

done < <(find "$SRC_DIR" -type d -print0)

# Print result array
if (( ${#bad_dirs[@]} )); then
  printf 'Folders added to array:\n'
  for d in "${bad_dirs[@]}"; do
    printf '  %s\n' "$d"
  done
else
  printf 'No folders added to array.\n'
fi
