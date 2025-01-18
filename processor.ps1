# Function to read INI file
function Get-IniContent ($filePath) {
    $ini = @{}
    switch -regex -file $filePath {
        "^\[(.+)\]" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "(.+?)\s*=(.*)" {
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value.Trim()
        }
    }
    return $ini
}

# Read settings
$settingsFile = Join-Path $PSScriptRoot "settings.ini"
if (-not (Test-Path $settingsFile)) {
    throw "Settings file not found: $settingsFile"
}
$settings = Get-IniContent $settingsFile

# Define paths from settings
$rootPath = $PSScriptRoot
$inputPath = Join-Path $rootPath $settings["Folders"]["InputPath"]
$outputPath = Join-Path $rootPath $settings["Folders"]["OutputPath"]
$archivePath = Join-Path $rootPath $settings["Folders"]["ArchivePath"]
$naps2Path = Join-Path $rootPath $settings["CoreBuild"]["Naps2Path"]
$magickPath = $settings["CoreBuild"]["ImageMagickPath"]
$logsPath = Join-Path $rootPath "logs"
$logFile = Join-Path $logsPath "processing_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Get processing settings
$useDeskew = [System.Convert]::ToBoolean($settings["Processing"]["Deskew"])
$imgCompression = $settings["Processing"]["Compression"]
$imgQuality = [int]$settings["Processing"]["Quality"]
$preProcessImage = [System.Convert]::ToBoolean($settings["Processing"]["PreProcessImage"])

# Create required directories if they don't exist
@($inputPath, $outputPath, $archivePath, $logsPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

# Function to write to log file
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    
    # Use mutex to prevent multiple processes from accessing the file simultaneously
    $mutex = New-Object System.Threading.Mutex($false, "Global\NAPS2_Log_Mutex")
    try {
        $mutex.WaitOne() | Out-Null
        [System.IO.File]::AppendAllText($logFile, "$logMessage`r`n")
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    
    Write-Host $logMessage
}

# Function to optimize image with ImageMagick
function Optimize-Image {
    param(
        [string]$inputPath,
        [string]$outputPath,
        [bool]$deskew,
        [string]$compression,
        [int]$quality
    )
    
    try {
        $magickArgs = @(
            "convert"
            $inputPath
        )

        if ($deskew) {
            $magickArgs += @("-deskew", "40%")
        }

        $magickArgs += @(
            "-compress", $compression
            "-quality", $quality
            $outputPath
        )
        
        & $magickPath $magickArgs 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
            return $true
        }
        return $false
    }
    catch {
        Write-Log "ImageMagick Error: $_"
        return $false
    }
}

Write-Log "Starting OCR processing..."

# Get all PDF files recursively from input folder
$files = Get-ChildItem -Path $inputPath -Recurse -File | Where-Object { $_.Extension -match '\.(pdf|tif|tiff|jpg|jpeg|png)$' }

# Group files by their full directory path relative to input folder
$fileGroups = $files | Group-Object { 
    $relativePath = $_.DirectoryName.Substring($inputPath.Length).TrimStart('\')
    if ([string]::IsNullOrEmpty($relativePath)) {
        "root"
    } else {
        $relativePath
    }
}

foreach ($group in $fileGroups) {
    try {
        $folderPath = $group.Name
        $folderName = Split-Path $folderPath -Leaf
        if ($folderName -eq "root") {
            $folderName = "root"
        }
        
        Write-Log "----------------------------------------"
        Write-Log "Processing folder: $folderName"
        Write-Log "Files found: $($group.Group.Count)"
        Write-Log "Path: $folderPath"
        Write-Log "----------------------------------------"
        
        # Create output directory using full relative path
        $outputDir = Join-Path $outputPath $folderPath
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }

        $processedFiles = @()
        foreach ($file in $group.Group) {
            if ($preProcessImage) {
                $tempDir = Join-Path $PSScriptRoot "temp"
                if (-not (Test-Path $tempDir)) {
                    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                }

                $optimizedPath = Join-Path $tempDir "$($file.Name)"
                if (Optimize-Image -inputPath $file.FullName -outputPath $optimizedPath -deskew $useDeskew -compression $imgCompression -quality $imgQuality) {
                    Write-Log "Input: $($file.Name) - Processed with ImageMagick"
                    $processedFiles += Get-Item $optimizedPath
                } else {
                    Write-Log "Input: $($file.Name) - ImageMagick processing failed, using original"
                    $processedFiles += $file
                }
            } else {
                Write-Log "Input: $($file.Name)"
                $processedFiles += $file
            }
        }

        $outputFileName = "$folderName.pdf"
        $outputFilePath = Join-Path $outputDir $outputFileName
        
        # Remove existing output file if it exists
        if (Test-Path $outputFilePath) {
            Remove-Item $outputFilePath -Force
            Write-Log "Removed existing file: $outputFileName"
        }
        
        Write-Log "Output: $outputFileName"
        Write-Log "----------------"

        # Create semicolon-separated list of input files
        $inputFiles = ($processedFiles | ForEach-Object { """$($_.FullName)""" }) -join ";"

        # Run NAPS2 OCR with all files
        & $naps2Path --noprofile -i $inputFiles -o "$outputFilePath" -n 0 --enableocr --ocrlang eng -f

        if ($LASTEXITCODE -eq 0) {
            # Move processed files to archive
            foreach ($file in $group.Group) {
                $archiveFilePath = Join-Path $archivePath $file.FullName.Substring($inputPath.Length + 1)
                $archiveDir = Split-Path $archiveFilePath -Parent
                
                if (-not (Test-Path $archiveDir)) {
                    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
                }

                Move-Item -Path $file.FullName -Destination $archiveFilePath -Force
                Write-Log "Archived: $($file.Name)"
            }
            
            Write-Log "Folder completed successfully"
        } else {
            Write-Log "ERROR: Folder processing failed"
        }

        Write-Log "----------------------------------------"
    }
    catch {
        Write-Log "Error: $_"
    }
}

if (Test-Path (Join-Path $PSScriptRoot "temp")) {
    Remove-Item (Join-Path $PSScriptRoot "temp") -Recurse -Force
}

Write-Log "Processing completed."