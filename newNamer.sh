#!/bin/bash

restructure() {
  if (( $# != 1 )); then
    printf 'Usage: restructure <root_dir>\n' >&2
    return 2
  fi
  local root="$1"
  if [[ ! -d "$root" ]]; then
    printf 'Error: not a directory: %s\n' "$root" >&2
    return 2
  fi

  # iterate directories
  while IFS= read -r -d '' dir; do
    # skip non-leaf dirs (has subdirectory)
    if find "$dir" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .; then
      continue
    fi

    # detect prefix from parent folder trailing digits
    local parent="$(basename -- "$dir")"
    local prefix=""
    if [[ $parent =~ ([0-9]+)$ ]]; then
      prefix="${BASH_REMATCH[1]}-"
    fi

    # collect non-.cbz files
    local -a numbered=() nonnumbered=()
    local i=0
    while IFS= read -r -d '' f; do
      local base="${f##*/}"
      # skip .cbz case-insensitive
      local lc="${base,,}"
      if [[ "${lc##*.}" == "cbz" ]]; then
        continue
      fi

      # split name/ext
      local name_no_ext ext
      if [[ "$base" == *.* ]]; then
        name_no_ext="${base%.*}"
        ext=".${base##*.}"
      else
        name_no_ext="$base"
        ext=""
      fi

      # first numeric substring (if any)
      if [[ $name_no_ext =~ ([0-9]+) ]]; then
        numbered+=("${BASH_REMATCH[1]}|$i|$f")
      else
        nonnumbered+=("${name_no_ext}|$i|$f")
      fi
      ((i++))
    done < <(find "$dir" -maxdepth 1 -type f -print0)

    # nothing to do
    if (( ${#numbered[@]} + ${#nonnumbered[@]} == 0 )); then
      continue
    fi

    # sort numbered numerically by the extracted number (stable)
    local -a ordered=()
    if (( ${#numbered[@]} )); then
      IFS=$'\n' read -r -d '' -a numbered < <(
        printf '%s\n' "${numbered[@]}" | sort -t'|' -k1,1n -s && printf '\0'
      )
      for e in "${numbered[@]}"; do ordered+=("$e"); done
    fi

    # sort non-numbered alphabetically (case-insensitive)
    if (( ${#nonnumbered[@]} )); then
      IFS=$'\n' read -r -d '' -a nonnumbered < <(
        printf '%s\n' "${nonnumbered[@]}" | sort -t'|' -k1,1f -s && printf '\0'
      )
      for e in "${nonnumbered[@]}"; do ordered+=("$e"); done
    fi

    # build target names and src list
    local -a srcs=() targets=()
    local idx=0
    for entry in "${ordered[@]}"; do
      IFS='|' read -r key origidx src <<<"$entry"
      srcs+=("$src")
      local b="${src##*/}"
      local ext=""
      if [[ "$b" == *.* ]]; then
        ext=".${b##*.}"
      fi
      targets+=("${prefix}${idx}${ext}")
      ((idx++))
    done

    # if all already correct, skip
    local all_good=1
    for k in "${!srcs[@]}"; do
      if [[ "$(basename -- "${srcs[$k]}")" != "${targets[$k]}" ]]; then
        all_good=0
        break
      fi
    done
    if (( all_good )); then
      continue
    fi

    # two-phase rename to avoid collisions
    local -a temps=()
    local rnd=$$
    for k in "${!srcs[@]}"; do
      local src="${srcs[$k]}"
      local tmp="$dir/.restruct_tmp_${rnd}_$k"
      # ensure unique temp name
      while [[ -e "$tmp" ]]; do tmp="${tmp}.$RANDOM"; done
      mv -- "$src" "$tmp"
      temps+=("$tmp")
    done

    # move temps to final targets (backup existing unexpected targets)
    for k in "${!temps[@]}"; do
      local tmp="${temps[$k]}"
      local target="$dir/${targets[$k]}"
      if [[ -e "$target" ]]; then
        mv -- "$target" "${target}.bak.${rnd}.$(date +%s%N)"
      fi
      mv -- "$tmp" "$target"
      printf 'Renamed: %s -> %s\n' "${tmp##*/}" "${targets[$k]}"
    done

  done < <(find "$root" -type d -print0)
}

# Example: 
restructure "/home/idle/Desktop/test"