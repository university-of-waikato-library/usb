Readme for DetectUSB

The three files in the DetectUSB directory support a USB storage device data collection and querying tool.

Data Store
Establish a data store using the file "USB_Device_20170606.sql" on a MySQL/MariaDB etc server of your choosing.


API
Mount the API file "index.php" on a web server of your choosing.
Edit "index.php" (lines 9, 10 and 11) to use the creds for your Datastore.


Client Script
Mount the Powershell script "usb.ps1" onto a client pc.

It is written in 2 parts:
Both parts query the WMI interface for the presence of USB devices. Both parts interact with a webserver API.
The part that runs by default calls the API to load any detected USB data associated with a user, to a database.
The alternate or second part will see if it can match a single USBs data to data stored in the database.

There are some conditional lines which will need adjusting for your local environment (lines 33, 36, 91 and 144)

For "normal" data harvesting operations
The script is written in a way that allows flexibility in how it can be called:
The easiest way is to use Group Policy. 
Trigger it using either ONSTART to run it as a service in the background independent of users.
OR
Trigger it using the user LOGON script trigger to run it only when users are logged in.
In both cases active querying occurs at 5 minute intervals.



To check for the owner of a USB. 
Normal setup is to have a shortcut on the desktop of selected front desk pc’s.
The shortcut calls PowerShell with two arguments: 
The first argument is the path to the script.
The second is literally anything (say an “X”). 
It is the presence of the second argument that changes the behaviour of the script.

Staff can then plug in a USB and run the script from the shortcut.
If the API finds fields in the database matching the USB in the PC, it will open a browser to display the data.
If the API does not find the USB in the database, it will advise this also in the browser

