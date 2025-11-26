#!/bin/bash

#test file
file=/home/idle/t-22.txt

#file info
ext="${file##*.}"
full_name="$(basename "$file")"
prefix="${full_name%%-*}"
name_with_no_prefix="${full_name#*-}"
base_file_name="$(basename "$file" | sed -E 's/^[^-]+-//; s/\.[^.]+$//')"

#show work
echo "$file"
echo "$full_name"
echo "$prefix"
#echo "$ext"
echo "$base_file_name"
#echo "$name_with_no_prefix"

