﻿Function Get-ADComputerCDRomInfo
{ 
        # Function variables
        $deviceId = ""
        $volumeName = ""
        $err = ""
        $makemkvpath = 'C:\Program Files (x86)\MakeMKV\'
        if (!(Test-Path $makemkvpath\makemkvcon.exe))
        {
            $makemkvpath = Read-Host 'What is your makemkvcon.exe folder path'
        }
        echo "Welcome to autorip."
        $dir1 = Read-Host 'Directory to save to: '
        $deviceId = Read-Host 'What is your disc drive letter (eg. D:): '
        
        try 
        {
            while (1-eq 1)
            {
                # Grab WMI object
            $w = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 5 and DeviceID = 'D:' " -errorvariable MyErr -erroraction Stop;       
                $w | ForEach-Object {
                    # Populate the properties
                    $deviceId = $_.DeviceID
                    $volumeName = $_.VolumeName
 
                    # If the drive letter length is 0, populate the default error
                    if ($deviceId.Length -eq 0) 
                    {
                        echo "No drive found."
                    }
                    elseif ($volumeName.Length -eq 0)
                    {
                        echo "No disc mounted."
                    }
                    else 
                    {
                        echo 'Mounted'
                        $dir1 = "C:\library\rips\$volumeName"
                        New-Item $dir1 -type directory -force
                        invoke-expression "$makemkvpath\makemkvcon.exe --minlength=1200 mkv disc:0 all C:\library\rips\$volumename\"
                        try
                        {
                        mv $dir1\title00.mkv $dir1\$volumeName.mkv
                        }
                        finally
                        {
                        }
                        ejectcd
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
    }

 
# Execute this function
Get-ADComputerCDRomInfo