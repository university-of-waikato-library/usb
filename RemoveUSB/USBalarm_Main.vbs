'Author:		Peter Stone
'Organisation:	University of Waikatio 
'Department:	Library, Technology Support Services
'wscript.echo "Main USB!"
'Written:		September 04, 2011 
'Updated:		November 22, 2011
'Filename:		USBalarm_Main.vbs
'Purpose:		Detect user's USB storage device. Notify user by Message Box and sound bite
'Version:       1.2
' -----------------------------------------------' 
'Option Explicit
Dim objWMIService, objItem, colItems, colProcessList, objProcess, objFilesys, objShell
Dim strAppData, strFolder, strFolderFileUSB, strFolderFileNir, strMsgFile, strMsgBoxRun
Dim strMediaPlayer, strComputer, strRunVol, strMediaPlayerApp
 
'On Error Resume Next
strComputer = "."

Set objWMIService = GetObject ("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery ("Select * from Win32_DiskDrive")

For Each objItem in colItems
	'Find any USB storage device the user has inserted...
	If objItem.InterfaceType = "USB" Then
		Set objFilesys = CreateObject("Scripting.FileSystemObject")
		Set objShell = Createobject("WScript.Shell")

		'Extract and Assign the path to the users local APPDATA directory
		Set objShell = Createobject("WScript.Shell")
		strAppData = objShell.ExpandEnvironmentStrings("%APPDATA%")
		'Assign the path to the RemoveUSB directory in the users local APPDATA directory
		strFolder = strAppData & "\RemoveUSB"
		
		'Run a separate script (USBalarmMsg.vb) that will display a warning on screen in 
		'a separate process and NOT wait for the (USBalarmMsg.vb) script to complete... 
		strMsgFile = strAppData & "\RemoveUSB\USBalarmMsg.vbs"
		If objFilesys.FileExists(strMsgFile) = True then
			strMsgBoxRun = """" & strMsgFile & """ /play /close "
			CreateObject("WScript.Shell").Run strMsgBoxRun,2,false
		End If
		
		' Use nircmd.exe to unmute and (nearly) max the sound volume
		strFolderFileNir = strAppData & "\RemoveUSB\nircmd.exe"
		If objFilesys.FileExists(strFolderFileNir) Then
			'Unmute and Increase the system volume (out of 65535)
			strRunVol = """" & strFolderFileNir & """ mutesysvolume 0"
			objShell.Run strRunVol, 2, True
			strRunVol = """" & strFolderFileNir & """ setsysvolume 64000"
			objShell.Run strRunVol, 2, True
			'Set the general volume
			strRunVol = """" & strFolderFileNir & """ setvolume 0 64000 64000"
			objShell.Run strRunVol, 2, True
		End If
		
		Wscript.Sleep 500
        
		'Use an imported media player application to run a sound file...
		strFolderFileUSB = strAppData & "\RemoveUSB\USB.wav"
		If objFilesys.FileExists(strFolderFileUSB) Then
			'Windows Media Player seems to be installed in both "C:\Program Files" AND "C:\Program Files (x86)" so we need to ensure only one 
			'location get "targeted" else we will end up with 4 instances of the sound bite "Remove your USB"
			strMediaPlayerApp = "C:\Program Files\Windows Media Player\wmplayer.exe" 
			If objFilesys.FileExists(strMediaPlayerApp) Then

				'MEDIA PLAYER LOCATION: Program Files (For 64 bit file installs)
				'Run the Media Player with a "Remove USB" sound bite in a separate process
				strMediaPlayerApp = "C:\Program Files\Windows Media Player\wmplayer.exe" 
				'Run the Media Player with a "Remove USB" sound bite in a separate process
				If objFilesys.FileExists(strMediaPlayerApp) Then
					strMediaPlayer = """" & strMediaPlayerApp & """ """ & strFolderFileUSB & """ --play-and-exit --quiet""" & """" 
					CreateObject("WScript.Shell").Run strMediaPlayer,2,False
				'Allow a pause for the sound bite to play					
				Wscript.Sleep 3500
 				End If

				'REPEAT media player call as sometime it can be slow/unresponsive on the first call
				'Kill any wmplayer process still running
				Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
				Set colProcessList = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'wmplayer.exe'")
				For Each objProcess in colProcessList 
					objProcess.Terminate() 
				Next
				If objFilesys.FileExists(strMediaPlayerApp) Then
					strMediaPlayer = """" & strMediaPlayerApp & """ """ & strFolderFileUSB & """ --play-and-exit --quiet""" & """" 
					CreateObject("WScript.Shell").Run strMediaPlayer,2,False
				'Allow a slightly longer pause for the sound bite to play					
				Wscript.Sleep 4500
 				End If
 			
			Else

				'MEDIA PLAYER LOCATION: Program Files (x86)
				'Run the Media Player with a "Remove USB" sound bite in a separate process
				strMediaPlayerApp = "C:\Program Files (x86)\Windows Media Player\wmplayer.exe" 
				'Run the Media Player with a "Remove USB" sound bite in a separate process
				If objFilesys.FileExists(strMediaPlayerApp) Then
					strMediaPlayer = """" & strMediaPlayerApp & """ """ & strFolderFileUSB & """ --play-and-exit --quiet""" & """" 
					CreateObject("WScript.Shell").Run strMediaPlayer,2,False
				'Allow a slightly longer pause for the sound bite to play					
				Wscript.Sleep 3500
 				End If

				'REPEAT media player call as sometimes it can be slow/unresponsive on the first call
				'Kill any wmplayer process still running
				Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
				Set colProcessList = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'wmplayer.exe'")
				For Each objProcess in colProcessList 
					objProcess.Terminate() 
				Next
				'Run the Media Player with a "Remove USB" sound bite in a separate process
				If objFilesys.FileExists(strMediaPlayerApp) Then
					strMediaPlayer = """" & strMediaPlayerApp & """ """ & strFolderFileUSB & """ --play-and-exit --quiet""" & """" 
					CreateObject("WScript.Shell").Run strMediaPlayer,2,False
				'Allow a pause for the sound bite to play					
				Wscript.Sleep 4500
 				End If
 			
			End If
 		End If

		'Kill any wmplayer process still running
		Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
		Set colProcessList = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'wmplayer.exe'")
		For Each objProcess in colProcessList 
			objProcess.Terminate() 
		Next
		 
		' Use nircmd.exe to (nearly)zero volume and/or mute it...
		If objFilesys.FileExists(strFolderFileNir) Then
			'Mute and/or Decrease the system volume (out of 65535)
			strRunVol = """" & strFolderFileNir & """ mutesysvolume 1"
			objShell.Run strRunVol
			strRunVol = """" & strFolderFileNir & """ setsysvolume 5000"
			objShell.Run strRunVol
			'Set the general volume
			strRunVol = """" & strFolderFileNir & """ setvolume 0 0 0"
			objShell.Run strRunVol
		End If
		
		'Ensure only one interation of this code block occurs - If there is more than one USB device...
		WSCript.Quit
	End If 
Next

WSCript.Quit