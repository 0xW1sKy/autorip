#usage: New-AutoRip -ToDir "C:\rips" -device "D"

function New-AutoRip {
[CmdletBinding()]
param (
    [string]$ToDir = "",
    [string]$Device = ""
    )
    # Function variables
    $DeviceID = ""
    $VolumeName = ""
    $Err = ""
    $MakeMKVPath = 'C:\Program Files (x86)\MakeMKV'
    if(!(Test-Path $ToDir)) {
        $ToDir = Read-Host -Prompt "Please enter path to save files to"
    }
    $Dir1 = $ToDir
    $Dir1 = $Dir1 -replace '\\','/'
    if($Dir1[$Dir1.Length -1] -eq '/') {
        $Dir1 = $Dir1.Substring(0,$($Dir1.length-1))
    }
    if (!(Test-Path $MakeMKVPath\makemkvcon.exe)) {
        $MakeMKVPath = Read-Host 'What is your makemkvcon.exe folder path'
    }
    Write-Host "Welcome to autorip-v2."
    if(!($Device)) {
        $Device = Read-Host -Prompt "Please enter your drive letter. Example: D"
    }
    $X = 0
    try {
        do {
            # Grab WMI object
            $W = Get-WmiObject -Class Win32_LogicalDisk -Errorvariable MyErr -ErrorAction Stop | Where-Object {
                ($_.DeviceID -like "*$Device*") -and ($_.DriveType -eq 5)
            } | Select-Object DeviceID, DriveType, VolumeName
            # Checks to see if it return more than one device
            if($W -is [System.Array]) {
                foreach($Device in $W) {
                    # Populate the properties
                    $DeviceID = $Device.DeviceID
                    $VolumeName = $Device.VolumeName
                    # If the drive letter length is 0, populate the default error
                    if ($DeviceID.Length -eq 0) {
                        Write-Host "No drive found."
                        $X++
                    }
                    elseif ($VolumeName.Length -eq 0) {
                        Write-Host "No disc mounted."
                        $X++
                    }
                }
            }
            # Only one device found
            else {
                $DeviceID = $W.DeviceID
                $VolumeName = $W.VolumeName
                Write-Host 'Mounted'
                $Dir2 = $Dir1 + '/' + $VolumeName
                if(!(Test-Path $Dir2)){
                    New-Item $Dir2 -Type Directory -Force
                }
            }
            &"$MakeMKVPath\makemkvcon.exe" "--minlength=300" "mkv" "disc:0" "all" "$Dir2"
            Remove-Media -id "$DeviceID"
            Write-Host "Rip Complete. Beginning Transcode."
            Get-ChildItem $Dir2 | ForEach-Object {
                New-TranscodeWithFFmpegGPU -MediaPath $_.fullname
            }
            Start-Sleep -Seconds 10
        }
        while ($X -lt 100)
    }
    Catch [System.Exception] {
        # Let's make sure we're populating the correct error
        if ($MyErr.Count -gt 0) {
            $Err = $MyErr
        }
        else {
            $Err = $Error[0].ToString()
        }
        Write-Host $Err
    }
    Finally {
        $FileList = Get-ChildItem "$Dir2/"
        $FileList | ForEach-Object {
            Write-Host $_.BaseName
        }
    }>
}
function Remove-Media{
    [CmdletBinding()]
    param($ID)
    $SA = New-Object -com Shell.Application
    $SA.Namespace(17).ParseName($ID).InvokeVerb("Eject")
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($SA) | Out-Null
    Remove-Variable SA
}
Function New-TranscodeWithFFmpegGPU {
    [CmdletBinding()]
    param (
        [string]$MediaPath = ""
    )
    $File = Get-Item -Path $MediaPath -ErrorAction Stop
    if($File.extension) {
    $ffmpeg = "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
        $oldFile = $File.DirectoryName + "\" + $File.BaseName + $File.Extension;
        $newFile = $File.DirectoryName + "\" + $File.BaseName + '-converted' + ".mkv";
        &$ffmpeg "-hide_banner" "-analyzeduration" "200M" "-probesize" "200M" "-n" "-fflags" "+genpts" "-hwaccel" "cuvid" "-c:v" "mpeg2_cuvid" "-i" "$oldFile" "-codec:v" "hevc_nvenc" "-preset" "llhq" "-b:v" "8M" "-codec:a" "copy" "-codec:s" "copy" "$newFile" 2>&1 | write-host
        Remove-Item $oldfile
    }
    else {
    Write-Host "Please Specify Media Path."
    Write-Host "Example: C:\your\path\to\file.mkv"
    }
}
