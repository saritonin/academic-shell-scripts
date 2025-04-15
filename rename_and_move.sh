#!/bin/bash

# SCRIPT: rename_and_move.sh
# USAGE: ./rename_and_move.sh <zip file OR extracted folder path>

# PURPOSE: Takes a Brightspace (D2L) submission download folder and reorganizes it.

# This makes my process for offline grading a lot easier by consolidating all 
# student work into a single folder and renaming the submissions to include the student
# name at the beginning of the filename. It also resets the file modified date to the
# file's submission time.

# Original folder structure:
#
# main_folder/
# ├── 397063-2557369 - Mary-Ann Smith - Sep 24, 2024 926 PM/
# │     └── document.pdf
# ├── 397063-2557369 - John Doe - Sep 24, 2024 926 PM/
# │     └── notes.txt
#
# Revised folder structure after rename_and_move.sh
# 
# main_folder/
# └── Mary Ann Smith | document.pdf
# └── John Doe | notes.txt

# This will NOT work for reimporting feedback into Brightspace, which requires you
# to leave the original folder and naming structure intact.

# Check if a .zip file or folder path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <.zip file OR folder path>"
  exit 1
fi

# The input ZIP file or folder path
input_path="$1"
echo "Processing $input_path"

# Check if the provided path is a valid ZIP file
if [ -f "$input_path" ] && [[ "$input_path" == *.zip ]]; then
  main_folder="${input_path%.zip}"
  unzip -q "$input_path" -d "$main_folder"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to unzip $input_path"
    exit 1
  fi
  echo "Unzipped to folder: $main_folder"

# Check if the provided path is a valid directory
elif [ -d "$input_path" ]; then
  main_folder="$input_path"

else
  echo "Error: '$input_path' is neither a valid .zip file nor a valid directory."
  exit 1
fi

# Loop through all subfolders in the main folder
for subfolder in "$main_folder"/*/; do
  if [ -d "$subfolder" ]; then
    subfolder_name=$(basename "$subfolder")
    echo "Processing subfolder: $subfolder_name"

    # Subfolder name chunks are delimited by " - " with the following format.
    # The (Group) chunk is only present for group assignment submissions.
    # Assignment Identifier - (Group) - Student Name - Submission Date

    # Extract the student's first and last name (always the 2nd to last chunk)
    first_last_name="$(echo $subfolder_name | awk -F ' - ' '{for(i=NF-1;i<NF;i++) print $i}')"
    echo "Extracted Name: $first_last_name"

    # Replace any non-alphabetic characters or extra spaces from the FirstName LastName
    first_last_name=$(echo "$first_last_name" | sed -E 's/[^a-zA-Z ]/ /g' | xargs)
    echo "Sanitized Name: $first_last_name"

    # Extract the submission date (always the last chunk)
    date_str=$(echo "$subfolder_name" | sed -E 's/.* - .+ - (.+)$/\1/')    
    echo "Extracted Date: $date_str"

    # Correct time format by adding a colon between hours and minutes (e.g., 911 PM -> 9:11 PM)
    date_str=$(echo "$date_str" | sed -E 's/([0-9]{1,2})([0-9]{2}) ([AP]M)/\1:\2 \3/')

    # Convert the extracted date to the format YYYYMMDDhhmm (for `touch -t`)
    formatted_date=$(date -j -f "%b %d, %Y %I:%M %p" "$date_str" +"%Y%m%d%H%M" 2>/dev/null)
    if [ -z "$formatted_date" ]; then
      echo "Warning: Could not parse date for $subfolder_name. Skipping date modification."
    else
      echo "Formatted Date: $formatted_date"
    fi

    # Loop through all files in the subfolder
    for file in "$subfolder"*; do
      if [ -f "$file" ]; then
        filename=$(basename "$file")

        # Create the new filename by prepending the sanitized FirstName LastName
        new_filename="${first_last_name} | $filename"

        # Move and rename the file to the main folder
        mv "$file" "$main_folder/$new_filename"
        echo "Moved: $file -> $main_folder/$new_filename"

        # Set the last modified date of the file (if the formatted date was successfully extracted)
        if [ -n "$formatted_date" ]; then
          touch -t "$formatted_date" "$main_folder/$new_filename"
          echo "Set last modified date for $main_folder/$new_filename to $formatted_date"
        fi
      fi
    done

    # Delete the subfolder (only if it's empty)
    rmdir "$subfolder"
    echo "Deleted subfolder: $subfolder"
  fi
done

# Delete index.html in the main folder if it exists
index_html="$main_folder/index.html"
if [ -f "$index_html" ]; then
  rm "$index_html"
  echo "Deleted: $index_html"
fi

echo "Rename, move, and date update completed."
