#!/bin/bash

# Check if a folder path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <folder_path>"
  exit 1
fi

# The input folder path
main_folder="$1"
echo "Main folder: $main_folder"

# Check if the provided path is a valid directory
if [ ! -d "$main_folder" ]; then
  echo "Error: '$main_folder' is not a valid directory."
  exit 1
fi

# Loop through all subfolders in the main folder
for subfolder in "$main_folder"/*/; do
  # Ensure the subfolder is a directory
  if [ -d "$subfolder" ]; then
    subfolder_name=$(basename "$subfolder")
    echo "Processing subfolder: $subfolder_name"

    # Loop through all files in the subfolder
    for file in "$subfolder"*; do
      # Ensure it's a file (not a directory)
      if [ -f "$file" ]; then
        # Get the filename
        filename=$(basename "$file")

        # Create the new filename by prepending the subfolder name
        new_filename="${subfolder_name}_$filename"

        # Move and rename the file to the main folder
        mv "$file" "$main_folder/$new_filename"
        echo "Moved: $file -> $main_folder/$new_filename"
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

echo "Rename and move completed." 

