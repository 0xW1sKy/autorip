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

    #usage: autorip-v2 -todir "C:\rips" -device "D"

Function autorip-v2
{ 

param (
    [string]$todir = "",
    [string]$device = "" 
    )
        # Function variables
        $deviceId = ""
        $volumeName = ""
        $err = ""
        $makemkvpath = 'C:\Program Files (x86)\MakeMKV'
        if(!(test-path $todir)){ $todir = read-host -Prompt "Please enter path to save files to" }
        $dir1 = $todir
        $dir1 = $dir1 -replace '\\','/'
        if($dir1[$dir1.Length -1] -eq '/'){$dir1 = $dir1.Substring(0,$($dir1.length-1)) }

        if (!(Test-Path $makemkvpath\makemkvcon.exe))
        {
            $makemkvpath = Read-Host 'What is your makemkvcon.exe folder path'
        }
        echo "Welcome to autorip-v2."
        if(!($device)){
        $device = read-host -prompt "Please enter your drive letter. Example: D"
        }
        $semicolon = ":"
        $x = 0
        
        try 
        {
            while ($x -lt 100)
            {
                # Grab WMI object
            $w = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 5 and DeviceID = '$device$semicolon' " -errorvariable MyErr -erroraction Stop;       
                $w | ForEach-Object {
                    # Populate the properties
                    $deviceId = $_.DeviceID
                    $volumeName = $_.VolumeName
 
                    # If the drive letter length is 0, populate the default error
                    if ($deviceId.Length -eq 0) 
                    {
                        echo "No drive found."
                        $x++
                    }
                    elseif ($volumeName.Length -eq 0)
                    {
                        echo "No disc mounted."
                        $x++
                    }
                    else 
                    {
                        echo 'Mounted'
                        $dir2 = $dir1 + '/' + $volumeName
                        if(!(test-path $dir2)){New-Item $dir2 -type directory -force}
                        &"$makemkvpath\makemkvcon.exe" "--minlength=300" "mkv" "disc:0" "all" "$dir2"
                        Eject -id "$deviceId"
                        echo "Rip Complete. Beginning Transcode."
                        get-childitem $dir2 | %{ Transcode-WithFFmpegGPU -mediaPath $_.fullname}
                    }
               }
            start-sleep -seconds 10
            }

            
        }
        Catch [system.exception]
        {
            # Let's make sure we're populating the correct error
            if ($MyErr.Count -gt 0) 
            {
                $err = $MyErr
    		} else {
                $err = $error[0].tostring()
            }
            echo $err
        }
        finally {
        $fileList = Get-ChildItem "$dir2/"
        $filelist |%{write-host $_.BaseName }
        }
    }


function Eject
{ 
    param($id)
    $sa = new-object -com Shell.Application 
    $sa.Namespace(17).ParseName($id).InvokeVerb("Eject") 
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($sa) | Out-Null
    Remove-Variable sa 
} 



Function Transcode-WithFFmpegGPU
{

param (
    [string]$mediaPath = ""
)

$file = Get-Item -Path $mediaPath -ErrorAction stop


if($file.extension){
$ffmpeg = "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
	$oldFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
	$newFile = $file.DirectoryName + "\" + $file.BaseName + '-converted' + ".mkv";
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
	$ffcmd = &$ffmpeg $ffargs 2>&1 | write-host
    remove-item $oldfile
}
else
{
Write-host "Please Specify mediaPath."
Write-host "Example: C:\your\path\to\file.mkv"
}
}
