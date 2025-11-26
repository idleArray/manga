#!/bin/bash

#traping to say bye :)
trap 'titleCard "goodbye!!!"; exit' SIGINT

#init vars
default_path="/home/idle/Desktop/test/"
sync_path="/media/idle/ghost/"
error=false
error_count="0"
menu_message=""

titleCard() {
  #function to display titleCard and info
  #takes one argument, info to display
  local message=$1

  clear
  echo "███╗   ███╗ █████╗ ███╗   ██╗ ██████╗  █████╗ ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗"
  echo "████╗ ████║██╔══██╗████╗  ██║██╔════╝ ██╔══██╗████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗"
  echo "██╔████╔██║███████║██╔██╗ ██║██║  ███╗███████║██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝"
  echo "██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██╔══██║██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗"
  echo "██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║"
  echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
  
  #adding subtext and space
  if [[ "$message" == "" ]]; then
    echo ""
  else
    echo "$message"
    echo ""
  fi
}

reportError() {
  #function to report errors
  #takes tree arguments
  #one, where the error happened
  #two, what message should accompany the error
  #three, what folder had the problem

  local error_location=$1
  local message=$2
  local specific=$3
  local path_to_report="$HOME/manga_maker_errors.txt"
  error=true
  ((error_count++))

  #check for error file
  if [[ ! -f "${path_to_report}" ]]; then
    touch "${path_to_report}"
  fi

  #appind to error file
  echo "Error report ${error_count}:" >> "${path_to_report}"
  echo " error location: ${error_location}" >> "${path_to_report}"
  echo " error: ${message}" >> "${path_to_report}"
  echo " target: ${specific}" >> "${path_to_report}"
  echo "" >> "${path_to_report}"
}

defaultPathCheck() {
  #take one arguments,
  #what to display on titleCard
  local message=$1
  while true; do
    titleCard "$message"
    echo "$default_path"
    echo "Would you like to use the default path? Y/n"
    read -r -p "> " ans

    if [[ "$ans" == "n" || "$ans" == "N" ]]; then
      echo ""
      echo "What path would you like to use?"
      read -r -p "> " path
      path="${path/#\~/$HOME}"

      if [[ ! -d "$path" ]]; then
        message="${path} is not a found folder"
        continue
      fi
      break

    elif [[ "$ans" == "y" || "$ans" == "Y" || -z "$ans" ]]; then
      path="$default_path"
      break

    else
      message="${ans} is not a valid entry"
    fi
  done

  echo "$path"
}

jobDone(){
  if $error; then
    titleCard "there was a problem"
  else
    titleCard "DONE!!!"
  fi
}

makePDFs() {
  #recursive function to make pdfs of png subfolders
  #must have one argument, root folder to look at
  #argument two, place to save pdfs, is optional
  local source=$1
  local save_to=$2
  local total_folders="$(find ${source} -type f -iname "*.png" -printf '%h\n' | sort -u | wc -l)"
  local count_folder=1

  #validate input folder
  if [ ! -d "$source" ]; then
    echo "Input folder '$source' not found."
    exit 1
  fi

  #if output folder provided, check it exists
  if [ -n "$save_to" ]; then
    if [ ! -d "$save_to" ]; then
      echo "Output folder '$save_to' not found."
      exit 1
    fi
    [[ "${save_to}" != */ ]] && save_to="${save_to}/"
  fi

  #loop over all subdirectories
  find "$source" -type d -print0 | sort -z | while IFS= read -r -d '' subfolder; do
    local total_files="$(find "$subfolder" -type f -iname "*.pdf" | wc -l)"
    local count_file=1

    #check for pre-exitsting pdf
    if [[ -n "$(find "$subfolder" -maxdepth 1 -type f -iname "*.pdf" -print -quit)"  ]]; then
      echo "we already have a pdf for ${subfolder}"
      continue
    fi

   #check if current folder houses any image files
    if ! find "$subfolder" -maxdepth 1 -type f -iname "*.png" -print -quit | grep -q .; then
      continue
    fi

    #make it pretty :)
    titleCard "png -> pdf: ${count_folder}/${total_folders}"

    #init array
    final_images=()

    #gather info to make pdf
    mapfile -t img_files < <(
      find "$subfolder" -maxdepth 1 -type f -iname "*.png" | sort -V
    )

    #setting pdf name depending on if save_to is given
    subfolder_name=$(basename "$subfolder")
    if [ -n "$save_to" ]; then
      output_file="${save_to}${subfolder_name}.pdf"
    else
      output_file="${subfolder}/${subfolder_name}.pdf"
    fi

    #beginning to process photos
    echo "Creating PDF for folder: $subfolder_name"

    #checking for non-valid photos
    for img in "${img_files[@]}"; do
      identify_output=$(identify "$img" 2>/dev/null)
      if [[ -z "$identify_output" ]]; then
        echo "  Skipping unreadable image: $(basename "$img")"
        reportError "makePDFs" "bad image" "$subfolder_name"
        continue
      fi

      #find and display photo info
      read w h < <(identify -format "%w %h" "$img")
      dpi=$(identify -format "%x x %y" "$img" | sed 's/ PixelsPerInch//g')
      echo "working on ${count_file}/${#img_files[@]}" "$(basename "$img") — Size: ${w}x${h} — DPI: $dpi"

      #if too small, img2pdf will error, so skip
      if (( w < 10 || h < 10 )); then
        echo "  Skipping tiny image: $(basename "$img") (${w}x${h})"
        reportError "makePDFs" "too small" "$subfolder_name"
        continue
      fi

      #we must check and fix problematic
      #should check code in the future
      #there may be a more efficient check
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
      ((count_file++))
    done

    if [ ${#final_images[@]} -eq 0 ]; then
      echo "  No valid images after processing. Skipping."
      reportError "makePDFs" "no images at end" "$subfolder_name"
      continue
    fi

    #doing the do
    if img2pdf "${final_images[@]}" -o "$output_file"; then
      echo "  Created: $output_file"
      ((count++))
    else
      echo "  ❌ Failed to create PDF for folder: $subfolder_name"
      reportError "makePDFs" "Failed to create PDF for folder" "$subfolder_name"
    fi

    #clean up any temporary fixed PNGs
    for img in "${final_images[@]}"; do
      [[ "$img" == *_fixed.png ]] && rm -f "$img"
    done
    ((count_folder++))
  done
}

pnger() {
  #recursive function to covert photos to png
  #takes one argument, root folder to look at
  local source=$1

  #validate input folder
  if [[ ! -d "$source" ]]; then
    echo "Error: "$source" is not a directory"
    exit 1
  fi
  
  #set up progress info with sorted files
  mapfile -t files < <(find "$source" -type f \( -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \) | sort)
  convertible_files=()
  for f in "${files[@]}"; do
    out="${f%.*}.png"
    if [[ ! -f "$out" ]]; then
      convertible_files+=("$f")
    fi
  done

  #init vars
  local total_files="${#files[@]}"
  local count=1

  for f in "${files[@]}"; do
    out="${f%.*}.png"
    if [ ! -f "$out" ]; then

      #we are ready to print info
      titleCard "pnger: ${count}/${total_files}"

      echo "${f##*/} -> ${out##*/}"

      #doing the do
      if convert "$f" "$out"; then
        rm -f "$f"
      else
        reportError "pnger" "failed to convert" "$f"
      fi
    fi
  ((count++))
  done

}

vaultSync() {
  local path_from=$1
  local message="sync manga FROM: ${path_from}"

  while true; do
    #checking if user wants to save to default sync path(ghost)
    titleCard "$message"
    echo "$sync_path"
    echo "would you like to sync to the default sync to path? Y/n"
    read -r -p "> " ans

    if [[ "$ans" == "y" || "$ans" == "Y" || -z "$ans" ]]; then
      break

    elif [[ "$ans" == "n" || "$ans" == "N" ]]; then
      echo ""
      echo "What path would you like to use?"
      read -r -p "> " path
      sync_path="${sync_path/#\~/$HOME}"

      if [[ ! -d "$sync_path" ]]; then
        message="${sync_path} is not a found folder"
        continue
      fi
      break      

      else
        message="sync manga FROM: ${path_from} !!! ${ans} is not a valid entry !!!"
      fi
    done

    #doing the do
    rsync -av --inclue="*.pdf" --include="*.xml" --exclude="*.png" "$path_from" "$sync_path"
}

restructure() {
  echo "import from desktop"
}

#main menu
titleCard "$menu_message"
while true; do
  echo "1: restructure folder"
  echo "2: convert photos to PNGs"
  echo "3: convert folder to PDFs"
  echo "4: sync manga"
  echo "5: quit"
  read -r -p "> " ans
  case $ans in
    1)
      defaultPathCheck "restructure"
      restructure "$path"
      jobDone
    ;;

    2)
      defaultPathCheck "pnger"
      pnger "$path"
      jobDone
    ;;

    3)
      defaultPathCheck "png -> pdf"
      makePDFs "$path"
      jobDone
    ;;

    4)
      defaultPathCheck "sync manga"
      vaultSync "$path"
      #jobDone
    ;;

    5|q)
      titleCard "goodbye!!!"
      exit 0
    ;;


    *) titleCard "${ans} is not a valid entry"
  esac
done