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

# Add Windows API import for GetShortPathName
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public class DllImporter {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetShortPathName(
            [MarshalAs(UnmanagedType.LPTStr)]
            string path,
            [MarshalAs(UnmanagedType.LPTStr)]
            StringBuilder shortPath,
            int shortPathLength
        );
    }
"@

# Function to get short path
function Get-ShortPath {
    param([string]$longPath)
    
    try {
        # Try using Windows API directly first
        $buffer = New-Object System.Text.StringBuilder(260)
        
        if ([System.IO.File]::Exists($longPath)) {
            $result = [System.Runtime.InteropServices.DllImporter]::GetShortPathName($longPath, $buffer, $buffer.Capacity)
            if ($result -ne 0) {
                return $buffer.ToString()
            }
        }

        # Fallback to Shell.Application if Windows API fails
        $shell = New-Object -ComObject Shell.Application
        if ($longPath.EndsWith('\')) {
            $longPath = $longPath.Substring(0, $longPath.Length - 1)
        }
        
        $folder = Split-Path $longPath
        $file = Split-Path $longPath -Leaf
        $shellFolder = $shell.NameSpace($folder)
        $shellFile = $shellFolder.ParseName($file)
        
        if ($shellFile) {
            return $shellFile.Path
        }

        # If both methods fail, try creating a temporary junction
        $tempJunction = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
        $null = New-Item -ItemType Junction -Path $tempJunction -Target (Split-Path $longPath) -Force
        try {
            $shortBase = Get-ShortPath $tempJunction
            $result = Join-Path $shortBase (Split-Path $longPath -Leaf)
            return $result
        }
        finally {
            Remove-Item $tempJunction -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Log "Warning: Could not get short path for $longPath. Using original path." "Warning"
        return $longPath
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

# Function to process files with NAPS2 (renamed to use approved verb)
function Invoke-FileProcessing {
    param($inputFiles, $outputFilePath)
    
    # Convert long paths to short paths
    Write-Log "Converting paths for processing..."
    $shortInputFiles = $inputFiles -split ";" | ForEach-Object { Get-ShortPath $_ }
    $shortOutputPath = Get-ShortPath $outputFilePath
    
    # Calculate total path length
    $totalLength = ($shortInputFiles -join ";").Length + $shortOutputPath.Length
    Write-Log "Total path length: $totalLength characters"
    
    if ($totalLength -gt 8000) {  # Windows command line limit is around 8191
        Write-Log "Path length exceeds limit. Processing in batches..." "Warning"
        
        # Process in smaller batches
        $batch = @()
        $batchLength = 0
        $batchCount = 1
        $totalFiles = $shortInputFiles.Count
        $processedCount = 0
        
        foreach ($file in $shortInputFiles) {
            $newLength = $batchLength + $file.Length + 1
            if ($newLength -gt 4000) {  # Conservative batch size
                # Process current batch
                Write-Log "Processing batch $batchCount with $(($batch).Count) files..."
                $tempOutput = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($shortOutputPath), 
                    "temp_batch_$batchCount.pdf")
                $batchFiles = $batch -join ";"
                
                Write-Log "Running NAPS2 OCR on batch $batchCount..."
                & $naps2Path -i "$batchFiles" -n 0 -o "$tempOutput"
                if ($LASTEXITCODE -ne 0) { 
                    Write-Log "Batch $batchCount failed with exit code $LASTEXITCODE" "Error"
                    throw "NAPS2 processing failed for batch $batchCount" 
                }
                Write-Log "Batch $batchCount completed successfully"
                
                $processedCount += $batch.Count
                Write-Log "Progress: $processedCount / $totalFiles files processed"
                
                $batch = @($file)
                $batchLength = $file.Length
                $batchCount++
            } else {
                $batch += $file
                $batchLength = $newLength
            }
        }
        
        # Process final batch
        if ($batch.Count -gt 0) {
            Write-Log "Processing final batch with $(($batch).Count) files..."
            $tempOutput = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($shortOutputPath), 
                "temp_batch_$batchCount.pdf")
            $batchFiles = $batch -join ";"
            
            Write-Log "Running NAPS2 OCR on final batch..."
            & $naps2Path -i "$batchFiles" -n 0 -o "$tempOutput"
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Final batch failed with exit code $LASTEXITCODE" "Error"
                throw "NAPS2 processing failed for final batch"
            }
            Write-Log "Final batch completed successfully"
        }
        
        # Merge all temporary PDFs
        Write-Log "Merging temporary PDFs..."
        $tempFiles = Get-ChildItem -Path ([System.IO.Path]::GetDirectoryName($shortOutputPath)) -Filter "temp_batch_*.pdf"
        if ($tempFiles.Count -gt 0) {
            Write-Log "Found $($tempFiles.Count) temporary PDFs to merge"
            
            # Prepare PDFtk command
            $tempFilePaths = $tempFiles.FullName -join " "
            $pdftkCommand = """$pdftkPath"" $tempFilePaths cat output ""$outputFilePath"""
            
            Write-Log "Executing PDFtk command: $pdftkCommand"
            $pdftkResult = cmd /c $pdftkCommand '2>&1'
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "PDFtk merge successful"
                
                # Verify output file exists and has content
                if (Test-Path $outputFilePath) {
                    $fileSize = (Get-Item $outputFilePath).Length
                    Write-Log "Output PDF created successfully. Size: $fileSize bytes"
                } else {
                    throw "PDFtk merge failed: Output file not created"
                }
                
                # Cleanup temp files
                Write-Log "Cleaning up temporary files..."
                $tempFiles | ForEach-Object {
                    Remove-Item $_.FullName -Force
                    Write-Log "Removed temporary file: $($_.Name)"
                }
            } else {
                Write-Log "PDFtk merge failed with exit code $LASTEXITCODE"
                Write-Log "PDFtk output: $pdftkResult"
                throw "PDFtk merge failed"
            }
        }
    } else {
        # Process normally if path length is acceptable
        Write-Log "Processing all files in single batch..."
        Write-Log "Running NAPS2 OCR..."
        
        # Ensure output directory exists
        $outputDir = Split-Path $outputFilePath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            Write-Log "Created output directory: $outputDir"
        }
        
        & $naps2Path -i "$inputFiles" -n 0 -o "$outputFilePath"
        $naps2ExitCode = $LASTEXITCODE
        
        Write-Log "NAPS2 Exit Code: $naps2ExitCode"
        
        if ($naps2ExitCode -eq 0) {
            if (Test-Path $outputFilePath) {
                $fileSize = (Get-Item $outputFilePath).Length
                Write-Log "Output file created successfully. Size: $fileSize bytes"
                if ($fileSize -eq 0) {
                    throw "NAPS2 created empty output file"
                }
            } else {
                throw "NAPS2 exit code 0 but output file not found at: $outputFilePath"
            }
            Write-Log "Processing completed successfully"
        } else {
            Write-Log "Processing failed with exit code $naps2ExitCode" "Error"
            throw "NAPS2 processing failed"
        }
    }
}

# Read settings
$settingsFile = Join-Path $PSScriptRoot "settings.ini"
if (-not (Test-Path $settingsFile)) {
    throw "Settings file not found: $settingsFile"
}
$settings = Get-IniContent $settingsFile

# Define paths from settings
# Join-Path $rootPath
$rootPath = $PSScriptRoot
$inputPath =  $settings["Folders"]["InputPath"]
$outputPath = $settings["Folders"]["OutputPath"]
$archivePath = $settings["Folders"]["ArchivePath"]
$naps2Path = $settings["CoreBuild"]["Naps2Path"]
$magickPath = $settings["CoreBuild"]["ImageMagickPath"]
$pdftkPath = $settings["CoreBuild"]["PdftkPath"]
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

# Add timer start before processing begins
$processingTimer = [System.Diagnostics.Stopwatch]::StartNew()
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

        # Run NAPS2 OCR with all files (updated function name)
        Invoke-FileProcessing -inputFiles $inputFiles -outputFilePath $outputFilePath

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

# At the end of the script, before final "Processing completed" message:
$processingTimer.Stop()
$totalTime = $processingTimer.Elapsed
Write-Log "----------------------------------------"
Write-Log "Total Processing Time:"
Write-Log "Hours: $($totalTime.Hours)"
Write-Log "Minutes: $($totalTime.Minutes)"
Write-Log "Seconds: $($totalTime.Seconds)"
Write-Log "Total Seconds: $($totalTime.TotalSeconds)"
Write-Log "----------------------------------------"
Write-Log "Processing completed."