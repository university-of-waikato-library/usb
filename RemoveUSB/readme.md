# Readme for RemoveUSB

## Quick start

1. Copy the directory `RemoveUSB` to the user `%AppData%` location
2. Extract `nircmd.exe` from `nircmd.zip` into the `RemoveUSB` directory
2. Plug in a USB
3. Run the file called `USBalarm_Main.vbs`

## Full instructions

There are 4 active files in the directory `RemoveUSB`. The whole directory `RemoveUSB` is set up to run from the users `%AppData%` folder.

The script to run is `USBalarm_Main.vbs` which should be related at `%AppData%\RemoveUSB\USBalarm_Main.vbs`.

`USBalarm_Main.vbs` detects if a USB is plugged in. If one is found:

1. It runs `USBalarmMsg.vbs` to display a warning on screen
2. It then calls `nircmd.exe` to raise the volume of the sound card
3. Using Windows Media Player, it plays the sound bite `USB.wav`
3. It then calls `nircmd.exe` to mute the volume of the sound card

#### To run using Group Policy

1. Copy the directory `RemoveUSB` to the user `%AppData%` location using Group Policy
2. Run the file called `USBalarm_Main.vbs` using a GPO logoff script pointed to `%AppData%\RemoveUSB\USBalarm_Main.vbs`

## Acknowledgement
`nircmd.exe` is from http://www.nirsoft.net/utils/nircmd.html
