# Readme for DetectUSB

The files in the DetectUSB directory support a USB storage device data collection and querying tool.

## Database

Import the provided schema in `USB_Device.sql` on a MySQL/MariaDB server.

You will need to create an account with `select`, `insert` and `update` privileges for the web API script.

## Web API

Tested with PHP 5.4 but should work with 7. Default name is `index.php` but can be renamed.

Place the `index.php` file on a web server of your choosing.

Edit the `/* Configuration */` section of `index.php` to provide the hostname and credentials to access your database.

If you are using Apache, you can also place the provided `.htaccess` file in the same directory to allow the API to be called without specifying the file name e.g. http://example.com/usb/?action=... instead of https://example.com/usb/index.php?action=... but it makes no functional difference.

## Client Script

Place the PowerShell script `usb.ps1` onto a client PCs.

It is written in 2 parts:
Both parts query the WMI interface for the presence of USB devices. Both parts interact with a webserver API.
The part that runs by default calls the API to load any detected USB data associated with a user, to a database.
The alternate or second part will see if it can match a single USBs data to data stored in the database.

There are some conditional lines which will need adjusting for your local environment (lines 33, 36, 91 and 144)

### For data harvesting operation

The script is written in a way that allows flexibility in how it can be called.
The easiest way is to use Group Policy.

It can be run:

* Using ONSTART to run it as a service in the background independent of users is recommended, or
* Using the user LOGON script trigger to run it only when users are logged in is also possible.

In both cases active querying occurs at 5 minute intervals.

### To check for the owner of a USB

Normal setup is to have a shortcut on the desktop of selected front desk PCs.
The shortcut calls `PowerShell.exe` with two arguments:  

1. The path to the script
2. Anything (say an `X`)

It is the presence of the second argument that changes the behaviour of the script.

Staff can then plug in a USB and run the script from the shortcut.

The script will open `chrome.exe` and display the result of the search.
