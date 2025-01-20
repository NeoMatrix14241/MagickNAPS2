# MagickNAPS2 for Sir Marc
A custom script that utilizes both ImageMagick 7 and NAPS2 for Image Preprocessing and OCR

# NAPS2 Batch OCR Processing Script

A PowerShell script for automated OCR processing of images using NAPS2 and ImageMagick, with support for folder structure preservation and image preprocessing.

## Features

- Processes multiple image formats (PDF, TIFF, JPG, PNG)
- Preserves folder structure in output
- Optional image preprocessing with ImageMagick
- Automated OCR using NAPS2
- Archiving of processed files
- Detailed logging system
- Configurable settings via INI file

## Requirements

- PowerShell 5.1 or higher
- [NAPS2](https://www.naps2.com/)
- [ImageMagick](https://imagemagick.org/) 7.x or higher
- [PDFtk Server](https://www.pdflabs.com/tools/pdftk-server/)

## Setup & Download

1. Clone this repository or [download](https://github.com/NeoMatrix14241/MagickNAPS2/releases/download/MagickNAPS2-v1.0.0.0/MagickNAPS2-v1.0.0.0.zip) the latest release
2. Configure `settings.ini` (The default values are below):
   ```ini
   [CoreBuild]
   Naps2Path=core\App\NAPS2.Console.exe
   ImageMagickPath=core\magick.exe

   [Folders]
   InputPath= C:\OCR\input
   OutputPath=C:\OCR\output
   ArchivePath=C:\OCR\archive

   [Processing]
   PreProcessImage=false
   Deskew=false
   Compression=JPEG
   Quality=50
   ```
3. Run `start_process.bat`

## Usage

1. Configure the `setup.ini` file for folder paths you want to OCR, where to save the files for archive after processing, and the output folder
2. Run the batch file `start_process.bat`
3. Check the output folder for processed PDFs
4. Original files will be moved to the archive folder
5. Check logs folder for processing details

## Features in Detail

- **Folder Structure**: Maintains source folder hierarchy in output
- **Batch Processing**: Processes all files in each folder into a single PDF
- **Image Optimization**: Optional preprocessing using ImageMagick
- **Error Handling**: Robust error handling with detailed logs
- **File Support**: Handles PDF, TIFF, JPG, PNG files
- **OCR**: Full text recognition using NAPS2's Tesseract OCR Engine

## Configuration Options

- **Deskew**: Enable/disable automatic image deskewing
- **Compression**: Set image compression type
- **Quality**: Adjust image quality (1-100)
- **Paths**: Configurable input/output/archive paths

## Notes

- Script automatically creates required folders
- Logs are created with timestamps
- Failed files remain in input folder
- Temporary files are automatically cleaned up
