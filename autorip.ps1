    #This program is free software; you can redistribute it and/or modify
    #it under the terms of the GNU General Public License as published by
    #the Free Software Foundation; either version 2 of the License, or
    #(at your option) any later version.

    #This program is distributed in the hope that it will be useful,
    #but WITHOUT ANY WARRANTY; without even the implied warranty of
    #MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    #GNU General Public License for more details.

    #You should have received a copy of the GNU General Public License along
    #with this program; if not, write to the Free Software Foundation, Inc.,
    #51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    #usage: New-AutoRip -ToDir "C:\rips" -device "D"

function New-AutoRip {
[CmdletBinding()]
param (
    [string]$ToDir = "",
    [string]$Device = ""
    )
    # Function variables
    $DeviceId = ""
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
        $Device = Read-Host -prompt "Please enter your drive letter. Example: D"
    }
    $SemiColon = ":"
    $X = 0
    try {
        do {
            # Grab WMI object
            $W = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 5 and DeviceID = '$Device$semicolon' " -errorvariable MyErr -erroraction Stop;
            foreach($Device in $W) {
                # Populate the properties
                $DeviceId = $Device.DeviceID
                $VolumeName = $Device.VolumeName
                # If the drive letter length is 0, populate the default error
                if ($DeviceId.Length -eq 0) {
                    Write-Host "No drive found."
                    $X++
                }
                elseif ($VolumeName.Length -eq 0) {
                    Write-Host "No disc mounted."
                    $X++
                }
                else {
                    Write-Host 'Mounted'
                    $Dir2 = $Dir1 + '/' + $VolumeName
                    if(!(Test-Path $Dir2)){
                        New-Item $Dir2 -Type Directory -Force
                    }
                    &"$MakeMKVPath\makemkvcon.exe" "--minlength=300" "mkv" "disc:0" "all" "$Dir2"
                    Remove-Media -id "$DeviceId"
                    Write-Host "Rip Complete. Beginning Transcode."
                    Get-ChildItem $Dir2 | ForEach-Object {
                        New-TranscodeWithFFmpegGPU -mediaPath $_.fullname
                    }
                }
            Start-Sleep -Seconds 10
            }
        }
        while ($X -lt 100)
    }
    Catch [system.exception] {
        # Let's make sure we're populating the correct error
        if ($MyErr.Count -gt 0) {
            $Err = $MyErr
        } else {
            $Err = $Error[0].tostring()
        }
        Write-Host $Err
    }
    Finally {
        $FileList = Get-ChildItem "$Dir2/"
        $FileList | ForEach-Object {
            Write-Host $_.BaseName
        }
    }
}
function Remove-Media
{
    [CmdletBinding()]
    param($id)
    $SA = New-Object -com Shell.Application
    $SA.Namespace(17).ParseName($id).InvokeVerb("Eject")
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($SA) | Out-Null
    Remove-Variable SA
}
Function New-TranscodeWithFFmpegGPU {
    [CmdletBinding()]
    param (
        [string]$MediaPath = ""
    )
    $File = Get-Item -Path $MediaPath -ErrorAction stop
    if($File.extension) {
    $ffmpeg = "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
        $oldFile = $File.DirectoryName + "\" + $File.BaseName + $File.Extension;
        $newFile = $File.DirectoryName + "\" + $File.BaseName + '-converted' + ".mkv";
        $ffarg1 = "-hide_banner"
        $ffarg2 = "-analyzeduration"
        $ffarg3 = "200M"
        $ffarg4 = "-probesize"
        $ffarg5 = "200M"
        $ffarg6 = "-fix_sub_duration"
        $ffarg7 = "-n"
        $ffarg8 = "-fflags"
        $ffarg9 = "+genpts"
        $ffarg10 = "-hwaccel"
        $ffarg11 = "cuvid"
        $ffarg12 = "-c:v"
        $ffarg13 = "mpeg2_cuvid"
        $ffarg14 = "-i"
        $ffarg15 = "$oldFile"
        $ffarg16 = "-map"
        $ffarg17 = "0"
        $ffarg18 = "-c"
        $ffarg19 = "copy"
        $ffarg20 = "-codec:v"
        $ffarg21 = "h264_nvenc"
        $ffarg22 = "-preset"
        $ffarg23 = "llhq"
        $ffarg24 = "-profile:v"
        $ffarg25 = "high"
        $ffarg26 = "-b:v"
        $ffarg27 = "5M"
        $ffarg28 = "-codec:a"
        $ffarg29 = "copy"
        $ffarg34 = "-codec:s"
        $ffarg35 = "copy"
        $ffarg36 = "$newFile"
        $ffargs = @( $ffarg1, $ffarg2, $ffarg3, $ffarg4, $ffarg5, $ffarg6, $ffarg7, $ffarg8, $ffarg9, $ffarg14, $ffarg15, $ffarg16, $ffarg17, $ffarg18, $ffarg19, $ffarg20, $ffarg21, $ffarg22, $ffarg23, $ffarg24, $ffarg25, $ffarg26, $ffarg27, $ffarg28, $ffarg29, $ffarg30, $ffarg31, $ffarg32, $ffarg33, $ffarg34, $ffarg35, $ffarg36)
        $ffcmd = &$ffmpeg $ffargs 2>&1 | Write-Host
        Remove-Item $oldfile
    }
    else {
    Write-Host "Please Specify mediaPath."
    Write-Host "Example: C:\your\path\to\file.mkv"
    }
}
