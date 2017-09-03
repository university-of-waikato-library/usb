Readme for RemoveUSB

Short Version:
1. Copy the directory "RemoveUSB" to the user %AppData% location.
2. Plug in a USB
3. Run the file called USBalarm_Main.vbs


Longer Version:
There are 4 active files in the dictory "RemoveUSB". The whole directory "RemoveUSB" is setup to run from the users %AppData% folder.
The one to run is "USBalarm_Main.vbs" (%AppData%\RemoveUSB\USBalarm_Main.vbs)

USBalarm_Main.vbs detects if a USB is plugged in. If one is found:
1. It runs "USBalarmMsg.vbs" to display a warning on screen. 
2. It then calls nircmd.exe to raise the volume of the sound card.
3. Using Windows media player, it plays the sound bite "USB.wav"
3. It then calls nircmd.exe to mute the volume of the sound card.

To run using Group Policy:
1. Copy the directory "RemoveUSB" to the user %AppData% location using a GPO logon script.
2. Run the file called USBalarm_Main.vbs using a GPO logoff script pointed to %AppData%\RemoveUSB\USBalarm_Main.vbs


Acknowledgement
The nircmd.exe is from http://www.nirsoft.net/utils/nircmd.html


