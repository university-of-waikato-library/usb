'Author:		Peter Stone
'Organisation:	University of Waikatio 
'Department:	Library, Technology Support Services
'Written:		September 04, 2011 
'Updated:		September 07, 2011
'Filename:		USBalarmMsg.vbs
'Version:       1.1
' -----------------------------------------------' 
Option Explicit

Dim wshShell, btn
Set wshShell = WScript.CreateObject("WScript.Shell")
'Display a Message dialogue on the user screen...
btn = wshShell.Popup("USB storage devices have been detected." & VbCrLf & "Remember to remove your USB stick! ", 15, "USB Warning!",48)
WSCript.Quit