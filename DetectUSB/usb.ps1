# Author:       Peter Stone
# Organisation:	University of Waikato
# Department:   Library Systems Team
# Purpose:      To insert or display the user details associated with USB devices from data stored in a database.
# Intended use: University computer equipment especially "public" computers where users often leave USB devises behind.
# Date:         2017-04-13 (Rewritten from an orginal concept script written 2016-03-03)

#####################################################################################
# Original query supplied by Fred to extract the data of any USB storeage device:
# gwmi win32_diskdrive | ? { $_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*' } | % { $_ | fl serialnumber,pnpdeviceid,mediatype,caption,size}

# Test for the presence of ANY argument supplied with the calling of this script. 
# If ANY argument exists, the script drops into the USB Database QUERY mode
if ($null -eq $args[0]) {$normalUSBdetection = $true} else {$usbDBquery = $true}

#region: USB DETECTION (normal)
        
# Only perform a data export IF the username returned is a WAIKATO domain user
if ($normalUSBdetection -eq $true) {
    write-host (get-date -format s) " Beginning USB DETECTION script..."
    # Write to log file (starting the file for the session)
    if (Test-Path C:\Windows\Libr\*.*) {((get-date -format s) + " Beginning USB DETECTION script...") | out-file 'C:\Windows\Libr\usb.txt' -Encoding utf8}
    
    # Register the WMI event class to use
    Register-WmiEvent -Class win32_DeviceChangeEvent -SourceIdentifier deviceChange
    
    # Begin an "endless loop"
    $previousUSBdetails = $null
    while (1 -eq 1) {
        # Establish a new Wait Event object...
        $newEvent = Wait-Event -SourceIdentifier deviceChange
        $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
        
        # Process ONLY device arrivals
        $USBdetails = @(); $USBdatalines = @();
        if ($eventType -eq 2) {
            # USER AND LOCATION
            # Extract the logged on user (if any) using the "Win32_ComputerSystem" namespace in WMI 
            # Doing it this way allows this script to run as under Computer Configuration or User Configuration in Group Policy
            $colItems = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $env:computername
            $loggedonuser = $null; foreach ($objItem in $colItems) {$loggedonuser = $objItem.UserName}
            # Experience has shown that the Win32_ComputerSystem namespace is NOT always reliable, so checking in with the .NET System.Security.Principal.WindowsIdentity provider
            if ($loggedonuser.length -le 1) {$loggedonuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name}
            
            # LIMITS AND EXCEPTIONS - Basiclly testing for and ensuing we process only valid network usernames from valid PC locations.
            $validusername = $false
            # "Belt and braces" here - confiming a "valid" username is deduced... (really for only if the script is run at logon...)
            if (!($loggedonuser -like 'WAIKATO\*')) {if ($env:USERDOMAIN -eq 'WAIKATO') {$loggedonuser = $env:USERDOMAIN + "\" + $env:USERNAME}}
            # Actioning only if it is a "WAIKATO" domain user logged on.... AND excepting a number of desk PCs where we would prefer this script did NOT run.
            if (($loggedonuser -like 'WAIKATO\*') -and ($env:computername -notlike "liby-*lend*") -and ($env:computername -notlike "liby-m-dis*") `
            -and ($env:computername -notlike "liby-*desk*") -and ($env:computername -notlike "liby-*dis*")) {
                $validusername = $true
            }

            # LOAD USB OR PORTABLE DRIVE DETAILS
            if ($true -eq $validusername) {
                # Get the details of any USB storage devices connected to the PC
                $USBdetails = get-wmiobject win32_diskdrive | Where-Object { ($_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*') -or ($_.mediatype -eq 'External hard disk media') }
        
                # On a practical level it seems like the device arrival is detected multiple times (in testing anywhere fron 3 to 7 times)
                # Pondering here: Maybe each USB device connected to the pc is triggering a device arrival event when a NEW device is registered?
                # The following comparison is to limit actions on detection of a storeage device(s) to only one "series" of detections...
                if (($USBdetails -ne $previousUSBdetails) -and  ($null -ne $USBdetails)) {
                    Write-host -ForegroundColor Green "STORAGE Device dectected..."; $USBdetails

                    foreach ($usbobject in $USBdetails) {
                        # Rationalise the usb data confirming NULL entries in serialNUMs... OR  single or two digit entries to NULL
                        # To be used, a serial number has to have more than two characters or numbers..... ALSO append Computername and Username data.
                        if (($usbobject.serialnumber).length -le 2) {$SN = $null} else {$SN = $usbobject.serialnumber}
                        # Ensure that the "|" pipe is NOT used in the string for the Device ID as it is being used by this process as a field separator
                        $USBdatalines += $SN + '|' + ($usbobject.pnpdeviceid).replace('|', '_') + '|' + $usbobject.mediatype + '|' + $usbobject.caption + '|' + $usbobject.size + '|' + $env:computername + '|' + $loggedonuser
                    }

                    # Lines of data to process INTO the database via the API
                    if ($null -ne $USBdatalines) {
                        foreach ($line in $USBdatalines) {
                            $url  = "https://library.waikato.ac.nz/usb/index.php?action=loaddb"
                            $url += "&serialnum="    + [uri]::EscapeDataString($line.split('|')[0])
                            $url += "&deviceid="     + [uri]::EscapeDataString($line.split('|')[1])
                            $url += "&mediatype="    + [uri]::EscapeDataString($line.split('|')[2])
                            $url += "&caption="      + [uri]::EscapeDataString($line.split('|')[3])
                            $url += "&sizebytes="    + [uri]::EscapeDataString($line.split('|')[4])
                            $url += "&computername=" + [uri]::EscapeDataString($line.split('|')[5])
                            $url += "&username="     + [uri]::EscapeDataString($line.split('|')[6])
                            
                            # Call the API with the $url
                            $site = (New-Object System.Net.WebClient).DownloadString("$url")

                            If ($site -like "*Record inserted OR updated*") {Write-Host -foreground Cyan "API advises: Record inserted OR updated"}
                            # Append to log file
                            If ($site -like "*Record inserted OR updated*") {if (Test-Path C:\Windows\Libr\*.*) {((get-date -format s) + " API advises: Record inserted OR updated") | out-file 'C:\Windows\Libr\usb.txt' -Encoding utf8 -Append}}
                        }
                    }
                }
                # On a practical level it seems like the device arrival is detected multiple times (in testing anywhere fron 3 to 7 times)
                # The $previousUSBdetails variable is used to limit actions on detection of a storeage device(s) to only one"series" of detections...
                $previousUSBdetails = $USBdetails
            }
        }
        Remove-Event -SourceIdentifier deviceChange
    }  #Loop until next event
    # For completeness Unregister the event - just that this line will never get called due to the endless loop!
    Unregister-Event -SourceIdentifier deviceChange
}

#endregion: USB DETECTION (normal)


#region: USB DETECTION (DBquery)

if ($usbDBquery -eq $true) {
    # Get the details of any USB storage devices connected to the PC
    $USBdetails = get-wmiobject win32_diskdrive | Where-Object { ($_.mediatype -eq 'Removable Media' -and $_.pnpdeviceid -like 'usbstor*') -or ($_.mediatype -eq 'External hard disk media') }
    if ($null -ne $USBdetails) {
        foreach ($usbobject in $USBdetails) {
            # Rationalise the usb data confirming NULL entries in serialNUMs... OR  single digit entries to NULL
            # BASICALLY to be used, a serial number has to have more than two characters or numbers.....
            if (($usbobject.serialnumber).length -le 2) {$SN = $null} else {$SN = $usbobject.serialnumber}
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
        if ($null -ne $USBdatalines) {
            write-host -f Green "Querying for USB/User from the Database..."; write-host
            foreach ($line in $USBdatalines) {
                $url  = "https://library.waikato.ac.nz/usb/index.php?action=querydb"
                $url += "&serialnum="    + [uri]::EscapeDataString($line.split('|')[0])
                $url += "&deviceid="     + [uri]::EscapeDataString($line.split('|')[1])
                $url += "&mediatype="    + [uri]::EscapeDataString($line.split('|')[2])
                $url += "&caption="      + [uri]::EscapeDataString($line.split('|')[3])
                $url += "&sizebytes="    + [uri]::EscapeDataString($line.split('|')[4])
                
                # Call the API invoking the chrome browser in the first instance
                if (test-path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {$chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"}
                if (test-path "C:\Program Files\Google\Chrome\Application\chrome.exe") {$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"}
                if ($null -ne $chrome) {
                    Start-Process -FilePath $chrome -ArgumentList $url
                    # NOTE: Start-Process was settled on after extensive testing of options and alternatives. The $url typically contains
                    #       a number of "special" characters ("&" "\" etc) that seem to break the API call, when used in the $url argument of
                    #       many of the other calling options (both Powershell and CMD). So avoiding "escape hell" within the assembled URL  
                    #       string, "Start-Process -FilePath $chrome -ArgumentList $url" seems to solve for this!
                } else {
                    # Call the API invoking the default browser Using a .NET static function 
                    # (Doing this is less certain than just opening in chrome and this may only work on Windows 10 in any case...)
                    [Diagnostics.Process]::Start($url,'arguments')
                }
            }
        }
    }
}

#endregion: USB DETECTION (DBquery)
