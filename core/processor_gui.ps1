Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'MagickNAPS2 - NAPS2 Batch OCR Processing Script'
$form.Size = New-Object System.Drawing.Size(600,500)
$form.StartPosition = 'CenterScreen'

# Folder Section Label
$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Location = New-Object System.Drawing.Point(10,10)
$folderLabel.Size = New-Object System.Drawing.Size(100,20)
$folderLabel.Text = 'Folders'
$folderLabel.Font = New-Object System.Drawing.Font($folderLabel.Font.FontFamily, 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($folderLabel)

# Input Path
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(10,40)
$inputLabel.Size = New-Object System.Drawing.Size(100,20)
$inputLabel.Text = 'Input Path:'
$form.Controls.Add($inputLabel)

$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Location = New-Object System.Drawing.Point(110,40)
$inputTextBox.Size = New-Object System.Drawing.Size(380,20)
$form.Controls.Add($inputTextBox)

$inputBrowse = New-Object System.Windows.Forms.Button
$inputBrowse.Location = New-Object System.Drawing.Point(500,40)
$inputBrowse.Size = New-Object System.Drawing.Size(75,20)
$inputBrowse.Text = 'Browse'
$inputBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $inputTextBox.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($inputBrowse)

# Output Path (similar to Input)
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(10,70)
$outputLabel.Size = New-Object System.Drawing.Size(100,20)
$outputLabel.Text = 'Output Path:'
$form.Controls.Add($outputLabel)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(110,70)
$outputTextBox.Size = New-Object System.Drawing.Size(380,20)
$form.Controls.Add($outputTextBox)

$outputBrowse = New-Object System.Windows.Forms.Button
$outputBrowse.Location = New-Object System.Drawing.Point(500,70)
$outputBrowse.Size = New-Object System.Drawing.Size(75,20)
$outputBrowse.Text = 'Browse'
$outputBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $outputTextBox.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($outputBrowse)

# Archive Path (similar to Input)
$archiveLabel = New-Object System.Windows.Forms.Label
$archiveLabel.Location = New-Object System.Drawing.Point(10,100)
$archiveLabel.Size = New-Object System.Drawing.Size(100,20)
$archiveLabel.Text = 'Archive Path:'
$form.Controls.Add($archiveLabel)

$archiveTextBox = New-Object System.Windows.Forms.TextBox
$archiveTextBox.Location = New-Object System.Drawing.Point(110,100)
$archiveTextBox.Size = New-Object System.Drawing.Size(380,20)
$form.Controls.Add($archiveTextBox)

$archiveBrowse = New-Object System.Windows.Forms.Button
$archiveBrowse.Location = New-Object System.Drawing.Point(500,100)
$archiveBrowse.Size = New-Object System.Drawing.Size(75,20)
$archiveBrowse.Text = 'Browse'
$archiveBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $archiveTextBox.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($archiveBrowse)

# Processing Section Label
$processingLabel = New-Object System.Windows.Forms.Label
$processingLabel.Location = New-Object System.Drawing.Point(10,140)
$processingLabel.Size = New-Object System.Drawing.Size(100,20)
$processingLabel.Text = 'Processing'
$processingLabel.Font = New-Object System.Drawing.Font($processingLabel.Font.FontFamily, 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($processingLabel)

# Preprocessing Checkbox
$preprocessCheckBox = New-Object System.Windows.Forms.CheckBox
$preprocessCheckBox.Location = New-Object System.Drawing.Point(10,170)
$preprocessCheckBox.Size = New-Object System.Drawing.Size(300,20)
$preprocessCheckBox.Text = 'Pre-Process Image (deskew/compression)'
$form.Controls.Add($preprocessCheckBox)

# Deskew Checkbox
$deskewCheckBox = New-Object System.Windows.Forms.CheckBox
$deskewCheckBox.Location = New-Object System.Drawing.Point(10,200)
$deskewCheckBox.Size = New-Object System.Drawing.Size(200,20)
$deskewCheckBox.Text = 'Deskew'
$form.Controls.Add($deskewCheckBox)

# Compression Dropdown
$compressionLabel = New-Object System.Windows.Forms.Label
$compressionLabel.Location = New-Object System.Drawing.Point(10,230)
$compressionLabel.Size = New-Object System.Drawing.Size(100,20)
$compressionLabel.Text = 'Compression:'
$form.Controls.Add($compressionLabel)

$compressionComboBox = New-Object System.Windows.Forms.ComboBox
$compressionComboBox.Location = New-Object System.Drawing.Point(110,230)
$compressionComboBox.Size = New-Object System.Drawing.Size(200,20)
$compressionComboBox.Items.AddRange(@('None','BZip','Fax','Group4','JPEG','JPEG2000','LosslessJPEG','LZW','RLE','Zip'))
$form.Controls.Add($compressionComboBox)

# Quality Slider
$qualityLabel = New-Object System.Windows.Forms.Label
$qualityLabel.Location = New-Object System.Drawing.Point(10,260)
$qualityLabel.Size = New-Object System.Drawing.Size(100,20)
$qualityLabel.Text = 'Quality:'
$form.Controls.Add($qualityLabel)

$qualityTrackBar = New-Object System.Windows.Forms.TrackBar
$qualityTrackBar.Location = New-Object System.Drawing.Point(110,260)
$qualityTrackBar.Size = New-Object System.Drawing.Size(200,45)
$qualityTrackBar.Minimum = 0
$qualityTrackBar.Maximum = 100
$qualityTrackBar.TickFrequency = 10
$form.Controls.Add($qualityTrackBar)

$qualityValue = New-Object System.Windows.Forms.Label
$qualityValue.Location = New-Object System.Drawing.Point(320,260)
$qualityValue.Size = New-Object System.Drawing.Size(50,20)
$qualityValue.Text = '50'
$form.Controls.Add($qualityValue)

$qualityTrackBar.Add_ValueChanged({
    $qualityValue.Text = $qualityTrackBar.Value.ToString()
})

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

# Function to save INI file
function Set-IniContent($ini, $filePath) {
    $content = @()
    foreach ($section in $ini.Keys) {
        $content += "[$section]"
        foreach ($key in $ini[$section].Keys) {
            $content += "$key=$($ini[$section][$key])"
        }
        $content += ""
    }
    $content | Set-Content $filePath -Force
}

# Save Button
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Location = New-Object System.Drawing.Point(250,400)
$saveButton.Size = New-Object System.Drawing.Size(100,30)
$saveButton.Text = 'Save'
$saveButton.Add_Click({
    try {
        $settingsPath = Join-Path $PSScriptRoot "settings.ini"
        $settings = @{
            'Folders' = @{
                'InputPath' = $inputTextBox.Text
                'OutputPath' = $outputTextBox.Text
                'ArchivePath' = $archiveTextBox.Text
            }
            'Processing' = @{
                'PreProcessImage' = $preprocessCheckBox.Checked.ToString().ToLower()
                'Deskew' = $deskewCheckBox.Checked.ToString().ToLower()
                'Compression' = $compressionComboBox.SelectedItem
                'Quality' = $qualityTrackBar.Value.ToString()
            }
            'CoreBuild' = @{} # Preserve existing CoreBuild settings
        }

        # Read existing settings to preserve CoreBuild section
        $existingSettings = Get-IniContent $settingsPath
        $settings['CoreBuild'] = $existingSettings['CoreBuild']

        Set-IniContent $settings $settingsPath
        [System.Windows.Forms.MessageBox]::Show("Settings saved successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error saving settings: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($saveButton)

# Add Start Process Button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(360,400)
$startButton.Size = New-Object System.Drawing.Size(100,30)
$startButton.Text = 'Start Process'
$startButton.Add_Click({
    try {
        $batPath = Join-Path $PSScriptRoot "start_process.bat"
        Start-Process $batPath -Wait
        [System.Windows.Forms.MessageBox]::Show("Processing completed!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error running process: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($startButton)

# Load initial values from INI file
try {
    $settingsPath = Join-Path $PSScriptRoot "settings.ini"
    $settings = Get-IniContent $settingsPath

    $inputTextBox.Text = $settings['Folders']['InputPath']
    $outputTextBox.Text = $settings['Folders']['OutputPath']
    $archiveTextBox.Text = $settings['Folders']['ArchivePath']
    
    $preprocessCheckBox.Checked = [System.Convert]::ToBoolean($settings['Processing']['PreProcessImage'])
    $deskewCheckBox.Checked = [System.Convert]::ToBoolean($settings['Processing']['Deskew'])
    $compressionComboBox.SelectedItem = $settings['Processing']['Compression']
    $qualityTrackBar.Value = [int]$settings['Processing']['Quality']
    $qualityValue.Text = $qualityTrackBar.Value.ToString()
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Error loading settings: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

# Show the form
$form.ShowDialog()
