#!/bin/bash

#looks for and counts all subfolder with photos
dir="/vault/homework/comics/hentai"

#function to make it recursive
findTheManga() {
	local current_dir=$1
	local count=0

	#check current folder
	for content in "$current_dir/"*; do
		((count++))
	done
	echo "$count"
}

#main code
total="$(findTheManga "$dir")"
echo "total: ${total}"