#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

# Folder containing the PDFs and images
FOLDER="$1"

# Add label to images
for IMAGE in "$FOLDER"/*.{jpg,jpeg,png,gif,bmp,tiff}; do
    if [ -f "$IMAGE" ]; then  # Check if it's a valid image file
        echo "Processing $IMAGE"
        
        # Extract the filename without extension
        BASENAME=$(basename "$IMAGE")
        FILENAME="${BASENAME%.*}"
        echo "Basename: $BASENAME"
        echo "Filename: $FILENAME"
        
        # Find the image's width so we can make the label match
        IMGWIDTH=$(identify -format %w "$IMAGE")
        echo "Width: $IMGWIDTH"
        
        # Add label to picture per https://usage.imagemagick.org/annotating/#anno_on
        magick -background '#0008' -fill white -gravity center -size ${IMGWIDTH}x30 \
        caption:"${FILENAME}" \
        "$IMAGE" +swap -gravity north -composite "$FOLDER/labeled_$BASENAME"
        
        echo "Label added to $IMAGE"
    fi
done

echo "Labeling completed for all images in the folder."

# Processing for all .doc and .docx 
for INPUT_DOC in "$FOLDER"/*.{doc,docx}; do
    if [ -f "$INPUT_DOC" ]; then # Check it's a valid file
        echo "Converting $INPUT_DOC"
        BASENAME=$(basename "$INPUT_DOC")
        FILENAME="${BASENAME%.*}"
        
        soffice --headless --convert-to pdf "$INPUT_DOC"
        echo "PDF created from $INPUT_DOC"
    fi
done


# Loop through all PDF files in the folder
for INPUT_PDF in "$FOLDER"/*.pdf; do
    if [ -f "$INPUT_PDF" ]; then  # Check if it's a valid file
        # Extract the filename without the path and extension
        BASENAME=$(basename "$INPUT_PDF")
        FILENAME=$(basename "$INPUT_PDF" .pdf)
        
        # Create a temporary label image with the filename
        magick -size 612x30 -font Helvetica -pointsize 12 -gravity center \
        -background "#0008" -fill white caption:"$FILENAME" "$FOLDER/temp_label.png"
 
        # Convert the temp_label image (PNG) to a PDF for pdftk compatibility
        magick "$FOLDER/temp_label.png" -page 612x792 -gravity north "$FOLDER/temp_label.pdf"
 
        # Target filename
        OUTPUT_PDF="$FOLDER/labeled_$BASENAME"
 
        # Add the watermark PDF to the top of each page of the PDF
        pdftk "$INPUT_PDF" stamp "$FOLDER/temp_label.pdf" output "$OUTPUT_PDF"

        # Clean up temporary files
       rm "$FOLDER/temp_label.png"
       rm "$FOLDER/temp_label.pdf"
       
       # TODO: Clean up temporary DOCX > PDF converted file

       echo "Label added to $INPUT_PDF"
    fi
done

echo "Labeling completed for all PDFs in the folder."
