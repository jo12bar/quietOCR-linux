#!/usr/bin/env bash

#===============================================================================
#
#          FILE:  quietOCR.sh
#
#         USAGE:  ./quietOCR.sh <inputFile>
#
#   DESCRIPTION:  OCR a file by creating a TIFF file and
#
#       OPTIONS:  -a, -h, -n
#  REQUIREMENTS:  
#          BUGS:  
#		 AUTHOR:  Nathan Nesbitt, nathan@nesbitt.ca
#       VERSION:  1.0
#       CREATED:  2019-05-21
#      REVISION:  R1
#         NOTES:  This script is designed to OCR one file at a time. It can
#		  be used to do a directory by specifying -a, but will run 
#		  differently ./quietOCR.sh -a <fullDirectoryPath>. If you want
#		  to get the text by itself, run it with the -n parameter after -a 
#		  (or first for single file).
#
#===============================================================================

## Installing requirements

# Installing homebrew if not installed
if [[ $(command -v brew) == "" ]]; then
	echo "Installing homebrew..."
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Installing imagemagick if not installed (Required for PDF --> TIFF)
if [[ $(brew ls --versions imagemagick) == "" ]]; then
	echo "installing imagemagick..."
	brew install imagemagick
fi

# Installing ghostscript if not installed (Required for TIFF --> PDF)
if [[ $(brew ls --versions ghostscript) == "" ]]; then
	echo "Installing ghostscript..."
	brew cask install ghostscript
fi

# Installing ocrmypdf if not installed (Required to create searchable PDF's) 
if [[ $(brew ls --versions ocrmypdf) == "" ]]; then
	echo "installing ocrmypdf..."
	brew install ocrmypdf
fi

# Help function
help () {
     cat << HELP_USAGE

 -h	Return help menu
 -a	Runs script on a directory
 -n	Saves the text as a text file, instead of in the PDF

 $0 -h
 $0 [-n]	<inputFile>
 $0 -a [-n] <fullDirectoryPath>
 
 Examples:
 
 $0 myFile.pdf 			# Single file with searchable text
 $0 -n myFile.pdf 		# Keeps original file and creates a new file with text from document
 $0 -a pwd 			# Makes all of the files in the current working directory searchable
 $0 -a /home/$USER/Documents/ 	# Makes all of the files in the documents directory searchable
 $0 -a -n pwd 			# creates text documents with the words from all of the files from the current directory

HELP_USAGE
}

# Function that takes a filename, and OCR's the file.
OCR () {
	# Removes the file extension
	filename=${filename%.*}
	echo $filename
	outputname="$filename.tiff"

	echo "Converting $filename.pdf to TIFF"
	$(convert -density 300 "$filename.pdf" -depth 8 -strip -background white -alpha off "$outputname")

	echo "OCRing"	
	tesseract "$outputname" "$filename new.pdf"

	echo " Done $filename new.pdf"
	rm "$outputname"
}

SEARCHABLE () {
	filename=${filename%.*}
	outputname="$filename new.pdf"
	echo "FILENAME: $filename"
	echo "OUTPUTFILE: $outputname"
	
	$(ocrmypdf "$filename.pdf" "$outputname")
	echo " Done $outputname"
}

if [ "-h" = $1 ];
then
	# Run help command
	help
else
	# Run folder
	if [ "-a" = $1 ]; 
	then
		if [ "-n" = $2 ]; 
		then
			for filename in "$($3)"/*.pdf; do
				echo "$filename"
				OCR
    		done
		else
			for filename in "$($2)/"*.pdf; do
				echo "$filename"
				SEARCHABLE
    		done
		fi	
	# Run on single file
	else
		if [ "-n" = $1 ]; 
		then
			filename=$2
			OCR
		else
			filename=$1
			SEARCHABLE
		fi
	fi
fi
