# Author:		Peter Stone
# Organisation:	University of Waikatio 
# Department:	Library Systems Team
# Purpose: 		To insert or display the user details associated with USB devices from data stored in a database.
# Intended use: University computer equipment especially "public" computers where users often leave USB devises behind.
# Date:         2017-04-13 (Rewritten from an orginal concept script written 2016-03-03)

#####################################################################################
# Original query supplied by Fred to extract the data of any USB storeage device:
# gwmi win32_diskdrive | ? { $_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*' } | % { $_ | fl serialnumber,pnpdeviceid,mediatype,caption,size}

# Test for the presence of ANY argument supplied with the calling of this script. 
# If ANY argument exists, the script drops into the USB Database QUERY mode
if ($args[0] -eq $null) {$normalUSBdetection = $true} else {$usbDBquery = $true}

#region: USB DETECTION (normal)
        
# Only perform a data export IF the username returned is a WAIKATO domain user
if ($normalUSBdetection -eq $true) {
    ##write-host -f Yellow "Normal detection..." (get-date -format "yyyy-MM-dd HH:mm:ss")
    # Intial delay to push first detection off for one minute from the script starting
    start-sleep 6
    
    # Begin an "endless loop" that will pause every 5 minutes... (as $x is never assigned '0" in the "while" loop)
    while ($x -ne 0) {
        $USBdetails = @(); $previousUSBs = @(); $USBdatalines = @(); $fileoutput = @(); $USBdatabaselines = @()
        
        # Extract the logged on user (if any) using the "Win32_ComputerSystem" namespace in WMI 
        # Doing it this way allows this script to run as under Computer Configuration or User Configuration in Group Policy
        $colItems = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $env:computername
        $loggedonuser = $null; foreach ($objItem in $colItems) {$loggedonuser = $objItem.UserName}
        # "Belt and braces" here - confiming a "valid" username is deduced... (really for only if the script is run at logon...)
        if (!($loggedonuser -like 'WAIKATO\*')) {if ($env:USERDOMAIN -eq 'WAIKATO') {$loggedonuser = $env:USERDOMAIN + "\" + $env:USERNAME}}

        # Actioning only if it is a "WAIKATO" domain user logged on.... AND not a desk PC
        if (($loggedonuser -like 'WAIKATO\*') -and ($env:computername -notlike "liby-*lend*") -and ($env:computername -notlike "liby-m-dis*") -and ($env:computername -notlike "liby-*desk*") -and ($env:computername -notlike "liby-*dis*")) {
            # Get the lines in the local log file (if it is present) of previous USB drive details then delete it.
            if (Test-Path C:\Users\Public\USB.txt) {$previousUSBs = get-content C:\Users\Public\USB.txt; Remove-Item  C:\Users\Public\USB.txt -Force}
            
            # Get the details of any USB storage devices connected to the PC
            $USBdetails = get-wmiobject win32_diskdrive | ? { $_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*' }
            if ($USBdetails -ne $null) {
                # Allowing for multiple USB storage devices - load arrays with the device data
                $SerialNumbers = @(); $pnpdeviceIDs = @(); $SmediaTypes = @(); $Captions = @(); $Sizes = @()
                foreach ($usbobject in $USBdetails) {
                    # Rationalise the usb data confirming NULL entries in serialNUMs... OR  single digit entries to NULL
                    # To be used, a serial number has to have more than two characters or numbers.....
                    if (($usbobject.serialnumber).length -le 2) {$SN = $null} else {$SN = $usbobject.serialnumber}
                    # Ensure that the "|" pipe is NOT used in the string for the Device ID as it is being used by this process as a field separator
                    $USBdatalines += $SN + '|' + ($usbobject.pnpdeviceid).replace('|', '_') + '|' + $usbobject.mediatype + '|' + $usbobject.caption + '|' + $usbobject.size
                }

                foreach ($USBdataline in $USBdatalines) {
                    # Filter for devices previously "seen" on this pc (loaded to $previousUSBs array).
                    if ($previousUSBs -ne $null) {
                        # Basiclly any USB device is logged locally when first detected.
                        foreach ($previousUSB in $previousUSBs) {
                            # Compare the first 5 fields of each dataline (spliting on "|" IF they are the same, then adjust the $USBdataline to the previously detected value...
                            # Doing this provides a way to avoid making another entry in the database for a different user for this USB storage device.
                            if (($USBdataline.split('|')[0] -eq $previousUSB.split('|')[0]) -and ($USBdataline.split('|')[1] -eq $previousUSB.split('|')[1]) -and ($USBdataline.split('|')[2] -eq $previousUSB.split('|')[2]) -and ($USBdataline.split('|')[3] -eq $previousUSB.split('|')[3]) -and ($USBdataline.split('|')[4] -eq $previousUSB.split('|')[4])) {$USBdataline = $previousUSB} 
                        }
                    }

                    # Test for the presence of the $env:computername in the $USBdataline - If it is NOT present, this means the data is a new USB entry substituted in the script block above.
                    if ($USBdataline.split('|')[5] -ne $env:computername) {
                        # The additional data fields that will be required for BOTH entry into the database AND rewriting of the local log file to the $USBdataline 
                        $USBdataline = $USBdataline + '|' + $env:computername + '|' + $loggedonuser + '|' + (get-date -format 'yyyy-MM-dd').ToString() + '|' + (get-date -format 'HH:mm:ss').ToString()
            
                        # Assign the $USBdataline to the $USBdatabaselines array that will be used to load into the database
                        $USBdatabaselines += $USBdataline
                    }
                    # Assign the $USBdataline to the $$fileoutput array that will be used to rewrite the local logfile
                    $fileoutput += $USBdataline
                }

                # Ensure there are no duplicate entries in either $fileoutput or $USBdatabaselines arrays and write output in the local log file at C:\Users\Public\USB.txt
                $fileoutput | Sort-Object -Unique | Out-File C:\Users\Public\USB.txt -Encoding ascii -Append
                $USBdatabaselines = $USBdatabaselines | Sort-Object -Unique

                # Negate any data in the $USBdatalines array so as to avoid conflict with the USB DETECTION (DBquery) below....
                $USBdatalines = @()
            }
        }
        
        # Calls to the MySQL database are being made indirectly using an API call on a web server. 
        # In this way there is no need to surface database access details into this script!

        # Lines of data to process INTO the database via the API
        if ($USBdatabaselines -ne $null) {
            foreach ($line in $USBdatabaselines) {
                $url  = "https://library.waikato.ac.nz/usb/index.php?action=loaddb"
                $url += "&serialnum="    + [uri]::EscapeDataString($line.split('|')[0])
                $url += "&deviceid="     + [uri]::EscapeDataString($line.split('|')[1])
                $url += "&mediatype="    + [uri]::EscapeDataString($line.split('|')[2])
                $url += "&caption="      + [uri]::EscapeDataString($line.split('|')[3])
                $url += "&sizebytes="    + [uri]::EscapeDataString($line.split('|')[4])
                $url += "&computername=" + [uri]::EscapeDataString($line.split('|')[5])
                $url += "&username="     + [uri]::EscapeDataString($line.split('|')[6])
                # Call the API with the $url
                (New-Object System.Net.WebClient).DownloadString("$url")
            }
        }
        start-sleep 300
    }
}

#endregion: USB DETECTION (normal)


#region: USB DETECTION (DBquery)

if ($usbDBquery -eq $true) {
    # Get the details of any USB storage devices connected to the PC
    $USBdetails = get-wmiobject win32_diskdrive | ? { $_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*' }
    if ($USBdetails -ne $null) {
        # Allowing for multiple USB storage devices - load arrays with the device data
        $SerialNumbers = @(); $pnpdeviceIDs = @(); $SmediaTypes = @(); $Captions = @(); $Sizes = @()
        foreach ($usbobject in $USBdetails) {
            # Rationalise the usb data confirming NULL entries in serialNUMs... OR  single digit entries to NULL
            # BASICLY to be used a serial number has to have more than one character or number.....
            if (($usbobject.serialnumber).length -le 1) {$SN = $null} else {$SN = $usbobject.serialnumber}
            # Ensure that the "|" pipe is NOT used in the string for the Device ID
            $USBdatalines += $SN + '|' + ($usbobject.pnpdeviceid).replace('|', '_') + '|' + $usbobject.mediatype + '|' + $usbobject.caption + '|' + $usbobject.size
        }
    }
    # Ensure there are no duplicate entries in $USBdatalines array
    $USBdatalines = @($USBdatalines | Sort-Object -Unique)
    
    # User interactions if pre-conditions are not met
    if ($USBdatalines.Count -lt 1) {
         Write-Host -ForegroundColor Yellow -BackgroundColor Red " PLEASE INSERT ONE USB DEVICE AND RE-RUN THIS SCRIPT... "
         Start-Sleep 5
    }
    if ($USBdatalines.Count -gt 1) {
         Write-Host -ForegroundColor Yellow -BackgroundColor Red " PLEASE PROCESS ONE USB DEVICE ONLY... "
         Start-Sleep 5
    }

    if ($USBdatalines.Count -eq 1) {
        # Set up a URL for the API to query the database
        if ($USBdatalines -ne $null) {
            write-host -f Green "Querying for USB/User from the Database..."; write-host
            foreach ($line in $USBdatalines) {
                $url  = "https://library.waikato.ac.nz/usb/index.php?action=querydb"
                $url += "&serialnum="    + [uri]::EscapeDataString($line.split('|')[0])
                $url += "&deviceid="     + [uri]::EscapeDataString($line.split('|')[1])
                $url += "&mediatype="    + [uri]::EscapeDataString($line.split('|')[2])
                $url += "&caption="      + [uri]::EscapeDataString($line.split('|')[3])
                $url += "&sizebytes="    + [uri]::EscapeDataString($line.split('|')[4])
                
                # Call the API invoking the chrome browser in the first instance
                $chrome -ne $null
                if (test-path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {$chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"}
                if (test-path "C:\Program Files\Google\Chrome\Application\chrome.exe") {$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"}
                if ($chrome -ne $null) {
                    Start-Process -FilePath $chrome -ArgumentList $url
                    # NOTE: Start-Process was settled on after extensive testing of options and alternatives. The $url typically contains
                    #       a number of "special" characters ("&" "\" etc) that seem to break the API call, when used in the $url argument of
                    #       many of the other calling options (both Powershell and CMD). So avoiding "escape hell" within the assembled URL  
                    #       string, "Start-Process -FilePath $chrome -ArgumentList $url" seems to solve for this!
                } else {
                    # Call the API invoking the default browser Using a .NET static function 
                    # (Doing this is less certain that just opening in chrome and this may only work on Windows 10 in any case...)
                    [Diagnostics.Process]::Start($url,’arguments‘)
                }
            }
        }
    }
}

#endregion: USB DETECTION (DBquery)