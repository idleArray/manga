#!/bin/bash

#used for vault folders so file name are standard
#takes no arguments, prints path of subfolders with bad named files
#good files names are (0++).ext or prefix-(0++).ext

#init var
dir="/vault/homework/comics/"

#checking folder
if [[ ! -d "$dir" ]]; then
  echo "ERROR: \$dir ${dir} is not valid."
  echo "please look to the code."
  exit 1
fi

#making the main logic a function so it can call itself
folderCheck() {
local current_dir="$1"
local count=0

#looping over all entries in the folder
find "$current_dir" -maxdepth 1 -type f | sort -V | while read -r file; do

  #getting info of file only if $file is a real file
  file_name="$(basename "$file")"
  file_prefix="${file_name%%-*}"
  file_plain="$(basename "$file" | sed -E 's/^[^-]+-//; s/\.[^.]+$//')"

  #check if there is a prefix, if so, check if valid
  if [[ "$file_prefix" != "$file_name" && ! "$file_prefix" =~ ^[0-9.]+$ ]]; then
    #then there is a prefix, but it is not a number
    echo ""
    echo "${current_dir}"
    echo "$file_name"
    break
  fi

  #resetting count if file base name = 0
  [[ "$file_plain" == 0 ]] && count=0

  #next is checking the file names
  if [[ ! "$file_plain" =~ ^[0-9]+$ || "$file_plain" != "$count" ]]; then
    #file either doesn't count sequentially from 0 or is not a number
    echo ""
    echo "${current_dir}"
    echo "$file_name"
  break
  fi
    #if file name is valid
    ((count++))
done

#makes the process_folder function recursive
for sub_dir in "${current_dir}"/*; do
  if [[ -d "$sub_dir" ]]; then
    #echo "$sub_dir"
    folderCheck "$sub_dir"
  fi
done
}

#main code lol
folderCheck "$dir"