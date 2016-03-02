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

$DefaultBackupFile = @LocalAppDataDir & "\Toms\Backup.reg"

Func LastRunScript($ScriptFriendlyName, $ScriptFile = "", $BackupFile = "")
	If $ScriptFile = "" Then $ScriptFile = @LocalAppDataDir & "\Toms\" & $ScriptFriendlyName & ".exe"
	If $BackupFile = "" Then $BackupFile = $DefaultBackupFile

	RegDelete("HKLM64\Software\TomsScript", "UpdateFailed")
	If FileExists(RegRead("HKLM64\Software\TomsScript", $ScriptFriendlyName)) Then
		FileDelete(RegRead("HKLM64\Software\TomsScript", $ScriptFriendlyName))
		RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", "TomsScript")
	EndIf
	If FileExists($ScriptFile) Then FileDelete($ScriptFile) ;This shouldn't be required. Still isn't removing it!

	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultDomainName")
	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultPassword")
	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","ForceAutoLogon")
	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","AutoAdminLogon" )
	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","AutoLogonCount")
	RegDelete("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultUserName")

	If FileExists($backupFile) Then
		ShellExecuteWait("reg.exe",  ' IMPORT "' & $backupFile & '" ', @TempDir)
		FileDelete($backupFile)
	Else
		MsgBox(327729, $ScriptFriendlyName, "Unable to find pre-work registery backup!")
	EndIf


	RunWait('Schtasks /Delete /TN "' & $ScriptFriendlyName & '" /F', "", @SW_HIDE)
	RegWrite("HKLM64\Software\TomsScript", "AutoLogin", "REG_SZ", 0)
EndFunc



Func FirstRunScript($ScriptFriendlyName, $ScriptFile="", $BackupFile = "")
	;Enable sensible defaults if blank.
	If $BackupFile = "" Then $BackupFile = $DefaultBackupFile
	If $ScriptFile = "" Then $ScriptFile = @LocalAppDataDir & "\Toms\" & $ScriptFriendlyName & ".exe"

	If RegRead("HKLM64\Software\TomsScript", "AutoLogin") = 1 Then Return ;We have done this before!

	;Test if this is actually a first run or not!
	$tempreg = @LocalAppDataDir & "\Toms.reg" ;For whatever reason putting this in a temporary folder fails!
	ShellExecuteWait("regedit.exe", ' /E "' & $tempreg & '" "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" ', @TempDir)
	FileMove($tempreg, $backupFile, 8);Copy the file, and if needed create the directory. Don't overwrite file if it exists
	If Not FileExists($backupFile) Then
		MsgBox(327729, $ScriptFriendlyName, "Attempted to create a backup and wasn't able to find that backup! Exiting!")
		Exit 43
	EndIf

	$invalid = 0;
	Do
		if $invalid Then MsgBox(1, $ScriptFriendlyName, "Invalid Windows Credentials")
		$user = InputBox ($ScriptFriendlyName, "Windows User?", @UserName)
		$domain = InputBox ($ScriptFriendlyName, "Domain?", @LogonDomain)
		$password = InputBox ($ScriptFriendlyName, "Windows Password?", "", "*M")
		$invalid+=1
		if $invalid = 5 Then
			MsgBox(327729, $ScriptFriendlyName, "For whatever reason unable to authenticate, giving up")
			Exit 28
		EndIf
	Until RunAs($user, $domain, $password, 0, @ComSpec & " /c  echo test", @SystemDir, @SW_Hide)

	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","AutoAdminLogon", "REG_SZ", 1 )
	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","AutoLogonCount", "REG_DWORD", 99)
	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultUserName", "REG_SZ", $user)
	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultDomainName", "REG_SZ", $domain)
	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","DefaultPassword", "REG_SZ", $password)
	RegWrite("HKLM64\Software\Microsoft\Windows NT\CurrentVersion\Winlogon","ForceAutoLogon", "REG_DWORD", 1)

	RegWrite("HKLM64\Software\TomsScript", "AutoLogin", "REG_SZ", 1)

	;;autorun on boot?
	FileCopy(@ScriptFullPath, $ScriptFile, 8);Copy the file, and if needed create the directory
	RegWrite("HKLM64\Software\TomsScript", $ScriptFriendlyName, "REG_SZ" ,$ScriptFile)
	RunWait('Schtasks /Create /TN "' & $ScriptFriendlyName & '" /RU ' & $domain & '\' & $user &' /RP ' & $password & ' /SC ONLOGON /RL HIGHEST /F /IT /TR "\"' & $ScriptFile & '"\"', "", @SW_HIDE)


EndFunc
