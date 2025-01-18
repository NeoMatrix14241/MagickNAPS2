# NAPS2 Batch OCR Processing Script

A PowerShell script for automated OCR processing of images using NAPS2 and ImageMagick, with support for folder structure preservation and image optimization.

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
- [NAPS2](https://www.naps2.com/) (Core Console version)
- [ImageMagick](https://imagemagick.org/) 7.x or higher (optional for preprocessing)

## Setup

1. Clone or download this repository
2. Configure `settings.ini`:
   ```ini
   [CoreBuild]
   Naps2Path=core\App\NAPS2.Console.exe
   ImageMagickPath=core\magick.exe

   [Folders]
   InputPath=input
   OutputPath=output
   ArchivePath=archive

   [Processing]
   Deskew=false
   Compression=JPEG
   Quality=50
   ```

3. Create the following folder structure:
   ```
   root/
   ├── input/         # Place input files here
   ├── output/        # OCR'd PDFs will be saved here
   ├── archive/       # Processed files are moved here
   └── logs/          # Processing logs
   ```

## Usage

1. Place your image files in the input folder, maintaining any folder structure you want to preserve
2. Run the script:
   ```powershell
   .\naps2-batch.ps1
   ```
3. Check the output folder for processed PDFs
4. Original files will be moved to the archive folder
5. Check logs folder for processing details

## Features in Detail

- **Folder Structure**: Maintains source folder hierarchy in output
- **Batch Processing**: Processes all files in each folder into a single PDF
- **Image Optimization**: Optional preprocessing using ImageMagick
- **Error Handling**: Robust error handling with detailed logs
- **File Support**: Handles PDF, TIFF, JPG, PNG files
- **OCR**: Full text recognition using NAPS2

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