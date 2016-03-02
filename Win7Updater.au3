#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Fileversion=0.0.2.1
#AutoIt3Wrapper_Res_LegalCopyright=Tom Tijerina
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Field=Copyright|Copyright (C) 2016 Tom Tijerina
#AutoIt3Wrapper_Res_Field=License|"This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>."
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
# Copyright (C) 2016 Tom Tijerina
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


#include <TomsLib.au3>

$ScriptFriendlyName = "Toms Updater"
$ScriptFriendlyID = "Toms"
$ScriptFile = @LocalAppDataDir & "\TomsScript\" & "TomsUpdate.exe"


If RegRead("HKLM64\Software\TomsScript", "UpdateFailed") Then
	$PreviousError = 1
Else
	$PreviousError = 0
EndIf


FirstRunScript($ScriptFriendlyName)
Run("wuapp.exe")

WinWait("Windows Update", "&Check for updates", 10)
WinActivate("Windows Update")
ControlClick("Windows Update", "", "&Check for updates")

Do	;Wait until it goes away.
	Sleep(300)
until ControlCommand("Windows Update", "", "[CLASSNN:msctls_progress322]", "IsVisible") = 0
Sleep(300)

;If we don't have updates, exit.
If Not WinWait("Windows Update", "&Install updates", 10) Then
  LastRunScript($ScriptFriendlyName)
  MsgBox(0, $ScriptFriendlyName, "I have finished updating windows." & @CR &"Some optional updates may remain.")
  Exit
Else ;We have updates.
	ControlClick("Windows Update", "", "&Install updates")

	Do	;Wait until the progress bar goes away...
		Sleep(300)
	until ControlCommand("Windows Update", "", "[CLASSNN:msctls_progress322]", "IsVisible") = 0

	if WinExists("Windows Update", "Try &again") Then
		If ($PreviousError) Then
			LastRunScript($ScriptFriendlyName)
			MsgBox(0, "", "I'm stuck at an error while attempting to update Windows. " & @CR & @CR &"Yes, I tried turning it off and back on again.")
		Else
			Do
				WinActivate("Windows Update")
				ControlClick("Windows Update", "", "Try &again")
				Sleep(300)
			until WinExists("Windows Update", "Try &again") = 0
			Do
				Sleep(300)
			until WinExists("Windows Update", "Try &again") Or WinExists("Windows Update", "&Restart now")

			If WinExists("Windows Update", "Try &again") Then
			  ;Create error file, to ensure we don't loop.
			  RegWrite("HKLM64\Software\TomsScript", "UpdateFailed", "REG_SZ", 1 )
			  Shutdown(2) ;Reboot
			  exit
			Else
				RegDelete("HKLM64\Software\TomsScript", "UpdateFailed")
				WinActivate("Windows Update")
				ControlClick("Windows Update", "", "&Restart now")
			EndIf
		EndIf
	Else ; We were able to do updates! Two options here, it asks for a reboot, or it says everything is fine. We will reboot in both cases.
	   if ($PreviousError) Then
		   RegDelete("HKLM64\Software\TomsScript", "UpdateFailed")
	   EndIf
	   Shutdown(2) ;Reboot
	   Exit
	EndIf
EndIf
