#!/usr/bin/env bash

#===============================================================================
#
#          FILE:  quietOCR.bash
#
#         USAGE:  ./quietOCR.bash <inputFile>
#
#   DESCRIPTION:  OCR a file by creating a TIFF file and
#
#       OPTIONS:  -a, -h, -n
#  REQUIREMENTS:
#          BUGS:
#		 AUTHOR:  Nathan Nesbitt, nathan@nesbitt.ca
# LINUX EDITION:  Johann M. Barnard, johann.b@telus.net
#       VERSION:  1.0
#       CREATED:  2019-06-07
#      REVISION:  R1
#         NOTES:  This script is designed to OCR one file at a time. It can
#		  be used to do a directory by specifying -a, but will run
#		  differently ./quietOCR.sh -a <fullDirectoryPath>. If you want
#		  to get the text by itself, run it with the -n parameter after -a
#		  (or first for single file).
#
#===============================================================================

## Installing requirements

PACKAGE_MANAGER_UPDATED=0

function update_package_manager() {
	if [[ "$PACKAGE_MANAGER_UPDATED" == 0 ]]; then
		if [[ $(command -v apt-get) ]]; then
			echo "Updating apt repositories. Need to use sudo."
			sudo apt-get update
		fi

		PACKAGE_MANAGER_UPDATED=1
	fi
}

function install_from_package_manager() {
	update_package_manager

	if [[ $(command -v apt-get) ]]; then
		echo "Installing $1 from apt. Need to use sudo."
		sudo apt-get install "$1" -y
	fi
}

# Installing imagemagick if not installed (Required for PDF --> TIFF)
if [[ ! $(command -v convert) ]]; then
	install_from_package_manager imagemagick
fi

# Installing ghostscript if not installed (Required for TIFF --> PDF)
if [[ ! $(command -v gs) ]]; then
	install_from_package_manager ghostscript
fi

# Installing ocrmypdf if not installed (Required to create searchable PDF's)
if [[ ! $(command -v ocrmypdf) ]]; then
	install_from_package_manager ocrmypdf
fi

# Help function
help() {
	cat <<HELP_USAGE

 -h, -?, --help			Return help menu
 -a, --all-pdfs			Runs script on a directory
 -n, --non-destructive	Saves the text as a text file, instead of in the PDF

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
function OCR() {
	# Removes the file extension
	filename="${1%.*}"
	echo "$filename"
	outputname="$filename.tiff"

	echo "Converting $filename.pdf to TIFF"
	$(convert -density 300 "$filename.pdf" -depth 8 -strip -background white -alpha off "$outputname")

	echo "OCRing"
	tesseract "$outputname" "$filename new.pdf"

	echo "Done $filename new.pdf"
	rm "$outputname"
}
export -f OCR # Allows function to be run in subshells.

function SEARCHABLE() {
	filename="${1%.*}"
	outputname="$filename new.pdf"
	echo "FILENAME: $filename"
	echo "OUTPUTFILE: $outputname"

	$(ocrmypdf "$filename.pdf" "$outputname")
	echo " Done $outputname"
}
export -f SEARCHABLE # Allows function to be run in subshells.

if [[ "-h" == "$1" || "-?" == "$1" || "--help" == "$1" || "" == "$1" ]]; then
	# Run help command
	help
	exit 0
else
	# Run folder
	if [[ "-a" == "$1" || "--all-pdfs" == "$1" ]]; then
		if [[ "-n" == "$2" || "--non-destructive" == "$2" ]]; then
			for filename in "$($3)"/*.pdf; do
				echo "$filename"
				OCR "$filename"
			done
		else
			find "$($2)" -printf 'Processing %p\n' -name '*.pdf' -exec bash -c 'SEARCHABLE "$0"' {} \;
		fi
		# Run on single file
	else
		if [[ "-n" == $1 || "--non-destructive" == "$1" ]]; then
			filename=$2
			OCR "$filename"
		else
			filename=$1
			SEARCHABLE "$filename"
		fi
	fi
fi
