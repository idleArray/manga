#!/usr/bin/env bash

#usage: ./restructure.sh <target_folder> <prefix>
#if prefix is empty, it is omitted (just "n.ext")
# -n for renaming starting at a new number instead of 0
# -a for adding the given preifx
# -r for removing the given prefix
#ex: restructure .                            renames all files in current directory to (0++).ext
#ex: restructure ~/my/folder/ 42              renames all files in ~/my/folder/ to 42-(0++).ext
#ex: restructure ~/my/folder/ -r 1            removes 1- from all 1-* named files in ~/my/folder/
#ex: restructure ~/my/folder/ -a music1       rename all files to have music1- added to the front of file name 
#ex: restructure ~/my/folder/ -n 50 test2     renames all files in ~/my/folder/ to test2-(50++).ext

#init vars
count=0
remove_toggle=false
prefix_toggle=false
prefix=""
target=""

#manually parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r)#remove prefix
      remove_toggle=true
      shift
      prefix="$1"
      ;;
    -a)#add prefix
      prefix_toggle=true
      shift
      prefix="$1"
      ;;
    -n)#change starting number
      shift
      count="$1"
      ;;
    -*)#bad flag
      echo "Unknown flag: $1"
      exit 1
      ;;
    *)#no flag
      if [[ -z "$target" ]]; then
        target="$1"
      elif [[ -z "$prefix" && "$remove_toggle" = false && "$prefix_toggle" = false ]]; then
        prefix="$1"
      fi
      ;;
  esac
  shift
done

#block of if's code for parsing input
#let user say . for current working directory
if [[ "$target" = "." ]]; then
  target="$PWD"
fi
#checking for no input
if [[ -z "$target" ]]; then
  echo "Usage: $0 <target_folder> <prefix>"
  exit 1
fi
#checking user directory
if [[ ! -d "$target" ]]; then
  echo "Error: $target is not a directory"
  exit 1
fi
#checking if prefix is valid
if [[ ! "${prefix}" =~ ^[a-zA-Z0-9.\ _-]*$ ]]; then
  echo "not a valid prefix-"
  exit 1
fi

#main code
if [[ "$remove_toggle" == true ]]; then
  find "$target" -type f -name "${prefix}*" | while read -r file; do
    #gathering relevant info
    full_name="$(basename "$file")"
    newname="${full_name#*-}"
    #rename action
    mv --no-clobber -- "$file" "$target/$newname"
  done; exit 0

elif [[ "$prefix_toggle" == true ]]; then
  find "$target" -maxdepth 1 -type f | sort -V | while read -r file; do
    #gathering relevant info
    full_name="$(basename "$file")"
    newname="${prefix}-${full_name}"
    #rename action
    mv --no-clobber -- "$file" "$target/$newname"
  done; exit 0

else
  #main branch, no flags given
  find "$target" -maxdepth 1 -type f | sort -V | while read -r file; do
    #gathering relevant info
    ext="${file##*.}"
    base="$(basename "$file")"

    #peventing things like photopng or filefile
    if [[ "$ext" == "$file" ]]; then
      ext=""
    else
      ext=".$ext"
    fi

    #rename if or if not prefix given
    if [[ -z "$prefix" ]]; then
      newname="${count}${ext}"
    else
      newname="${prefix}-${count}${ext}"
    fi

    #rename action
    mv --no-clobber -- "$file" "$target/$newname"
    ((count++))
  done; exit 0
fi