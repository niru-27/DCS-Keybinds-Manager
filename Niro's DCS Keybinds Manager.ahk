;Needs older AHK v1.1
;Script ver 0.4b
;No need to manually create LUAs via DCS. Should auto detect UUIDs thanks to evilC's JoystickWrapper library
;https://github.com/evilC/JoystickWrapper
;Download above library and put the DLL and AHK files next to this script
version=0.4b
;Get latest version from: https://github.com/niru-27/DCS-Keybinds-Manager
;=========================================================
#NoEnv 							; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.
DetectHiddenWindows, On
#SingleInstance, Force
#Include JoystickWrapper.ahk
global jw := new JoystickWrapper("JoystickWrapper.dll")

;=========================================================
;Path to target DCS Saved Games Folder to be MODIFIED
SGfolder = C:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input

;=========================================================
;Path to BACKUP source folder. Will never be modified
Backup =
;=========================================================
;=========================================================
;=========================================================

;Gui, New,,Niro's DCS Keybinds Manager
Gui, Add, Button, gTargetFolder x10 y10 w100 h30, Target "Input" Folder
Gui, Add, Edit, x115 y15 w320 vTarget, %SGfolder%

Gui, Add, Button, gBackupFolder x800 y10 w100 h30, Backup "Input" Folder
Gui, Add, Edit,x475 y15 w320 vBk Right, %Backup%

Gui, Add, Button, gHelp x438 y10 w35 h35, Help

Gui, Add, ListView, x0 y110 r20 w900, Device Name|Current UUID|Old UUID
LV_ModifyCol(1,400)
LV_ModifyCol(2,250)
LV_ModifyCol(3,240)

Gui, Add, StatusBar,, 

Gui, Add, Button, gRescan w180 h50 x10 y50, Rescan
Gui, Add, Button, gImport Default w180 h50 x350 y50, <---- Import
Gui, Add, Button, gExport w180 h50 x720 y50, Backup ---->
Gui, Show,,Niro's DCS Keybinds Manager - v%version%

return

;=========================================================
;=========================================================
;=========================================================
Rescan:
If(Backup = "")							;Validate Backup path
{
	SB_SetText("Set Backup location first")
	return
}
IfNotExist, %SGfolder%					;Validate Target path
{
	SB_SetText("Set Target location first")
	return
}

SB_SetText("Searching...")
Sleep,1000
LV_Delete()
modules:=""
repl := []					;Old name, New name
i:=0						;No. of devices
k:=0						;No. of modules found
devices:=""
new_devices:=""
;=========================================================
;Get current device UUID using JoystickWrapper
global DeviceList := jw.GetDevices()				;DirectInput devices
global XinputDeviceList := jw.GetXInputDevices()	;XInput controllers

Loop, %Backup%\*,2									;Loop through each module
{
	curr_mod:=A_LoopFileName
	;MsgBox,	%curr_mod%`n`n%Backup%\%curr_mod%\joystick\
	modules=%modules%%curr_mod%`n
	k:=k+1
	
	Loop,%Backup%\%curr_mod%\joystick\*.diff.lua		;Loop through each device
	{
		RegexMatch(A_LoopFileName,"O)(.*) (\{.*\})",Match)
		old_name := % Match[1]
		old_UUID := % Match[2]
		;MsgBox,	%curr_mod%`n%old_name%`n%old_UUID%
		
		;Joysticks/DirectInput
		for d, dev in DeviceList
		{
			new_name:=dev.Name
			new_UUID:=dev.Guid
			new_UUID={%new_UUID%}
			if(old_name = new_name)
			{
				If(!Instr(devices,old_name) && !Instr(old_name,"vJoy"))
				{
					devices=%devices%%old_name%`n
					;Store new and old UUID as key-value pair
					repl[old_UUID] := new_UUID
					i:=i+1
					LV_Add("",old_name,new_UUID,old_UUID)
					SB_SetText("Searching..." . i . " devices found in " . k . " modules")
					;MsgBox,	%old_name%`n%old_UUID%`n%new_UUID%
					Sleep, 20
				}
			}
		}
		
		;XInput : Xbox controllers should work, but untested
		for d, dev in XinputDeviceList
		{
			new_name:=dev.Name
			new_UUID:=dev.Guid
			new_UUID={%new_UUID%}
			if(old_name = new_name)
			{
				If(!Instr(devices,old_name) && !Instr(old_name,"vJoy"))
				{
					devices=%devices%%old_name%`n
					;Store new and old UUID as key-value pair
					repl[old_UUID] := new_UUID
					i:=i+1
					LV_Add("",old_name,new_UUID,old_UUID)
					SB_SetText("Searching..." . i . " devices found in " . k . " modules")
					;MsgBox,	%old_name%`n%old_UUID%`n%new_UUID%
					Sleep, 20
				}
			}
		}
	}
	SB_SetText("Searching..." . i . " devices found across " . k . " modules")
					Sleep, 20
}
;MsgBox,	%k% modules found:`n`n%modules%
;=========================================================
LV_ModifyCol(1,"Sort Text")					;Sort list alphabetically

if(!i)
{
	SB_SetText("No devices found...Check both paths & ensure your devices are connected to your PC to detect current UUID")
	MsgBox,	No matching devices found between target <--> Backup folders.`n`n1) Verify both paths and try again`n`nDefault OB =`nC:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input`n`n`t<OR>`n`nDefault Stable =`nC:\Users\%A_Username%\Saved Games\DCS\Config\Input`n`n`n2) Ensure your devices are connected to your PC to detect current UUID
}else
{
	SB_SetText(i . " devices found across " . k . " modules. Ready to import")
}

If(devices!="" && 0)
	MsgBox,	Found matching binds for %i% devices:`n`n%devices%

return

GuiClose:
Esc::ExitApp

;=========================================================
;=========================================================
;=========================================================
Import:
If(Backup="")
{
	MsgBox,48,Error,Set backup location first to the "Input" folder that contains all the modules
	return
}

Gosub AutoExport		;Backup first in case you want to undo later

j:=1					;No. of LUA's imported
k:=0					;No. of modules found

SB_SetText("Importing...")
Sleep,500

;Replace UUID in file name
;Loop through each module to be imported
Loop, %Backup%\*,2
{
	curr_mod:=A_LoopFileName
	k:=k+1
	SB_SetText("Importing... `t" . curr_mod)
	
	Loop, %Backup%\%curr_mod%\joystick\*.diff.lua					;Loop through each device in current module
	{
		If(A_LoopFileName!="" && !Instr(A_LoopFileName,"vJoy"))		;Ignore vJoy devices
		{
			RegexMatch(A_LoopFileName,"O)(.*) (\{.*\})",Match)
			old_dev_name := % Match[1]								;Device 
			old_UUID := % Match[2]									;UUID from filename
			
			;MsgBox,	%old_dev_name%`no=%old_UUID%`n`nk=%key%`nv=%value%
			
			For key, value in repl
			{
				;MsgBox %j%>`n`n%key%`n ==> `n%value%
				
				If(old_UUID=key)
				{
					;Ensure joystick folder exists
					FileCreateDir, %SGfolder%\%curr_mod%\joystick\
					;Copy backup file and rename to new UUID
					FileCopy, %Backup%\%curr_mod%\joystick\%A_LoopFileName%, %SGfolder%\%curr_mod%\joystick\%old_dev_name% %value%.diff.lua, 1
						
					j:=j+1
				}
			}
		}
	}
	
	;Copy keyboard, mouse, TrackIR and modifiers binds
	FileCopyDir, %Backup%\%curr_mod%\keyboard\, %SGfolder%\%curr_mod%\keyboard\, 1
	FileCopyDir, %Backup%\%curr_mod%\mouse\, %SGfolder%\%curr_mod%\mouse\, 1		
	FileCopyDir, %Backup%\%curr_mod%\mouse\, %SGfolder%\%curr_mod%\trackir\, 1		
	FileCopy, %Backup%\%curr_mod%\modifiers.lua, %SGfolder%\%curr_mod%\modifiers.lua, 1	
}	

j:=j-1
SB_SetText("`t>> Replacing UUID inside files, please wait <<")

;=========================================================
;=========================================================
;Replace UUID in file content
l:=""
Loop, Files, %SGfolder%\modifiers.lua, FR					;Loop through all modifiers.lua files
{
	l=%l%%A_LoopFileFullPath%`n
	
	FileRead, content, %A_LoopFileFullPath%
	
	For key, value in repl
	{
		content := StrReplace(content, key, value)
	}
	
	FileDelete, %A_LoopFileFullPath%
	FileAppend, %content%,%A_LoopFileFullPath%
}

;MsgBox,	%l%
if(j)
{
	SB_SetText(j . " LUA's imported successfully for " . i . " devices across " . k . " modules")
	MsgBox,64,Success!,	%j% LUA's imported successfully for %i% devices across %k% modules,15
}
else
{
	SB_SetText(j . "No devices found.  Make sure your devices are connected to your PC to detect current UUID")
	MsgBox,64,Niro's DCS Keybinds Manager,No devices found`n`nMake sure your devices are connected to your PC to detect current UUID
}
return

;=========================================================
;=========================================================
;=========================================================
;Set Saved Games/Target folder button
TargetFolder:
	FileSelectFolder, SG2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select DCS Saved Game profile folder to be modified
	if(SG2 != "")
	{
		GuiControl,, Target, %SG2%
		SGfolder:=SG2
		
		IfNotExist, %SGfolder%					;Validate Target path
		{
			SB_SetText("Set Target location first")
			return
		}
		Goto Rescan
	}
return

;=========================================================
;=========================================================
;=========================================================
;Set Backup folder button
BackupFolder:
	FileSelectFolder, BK2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select Backup location to import from
	if(BK2 != "")		
	{
		GuiControl,, Bk, %BK2%
		Backup:=BK2
		Goto Rescan
	}
	else SB_SetText("Set Backup location first")
return

;=========================================================
;=========================================================
;=========================================================
;Export button
Export:
	;MsgBox,	FileSelectFile, SaveZIP,2,%Backup%1234.zip
	SB_SetText("Exporting... ")
	FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss					;Change timestamp format here
	SplitPath, Backup,,ExportLocation
	FileSelectFile, SaveZIP,S2,%ExportLocation%\DCS_%TimeString%.zip,Choose export location,*.zip
	Clipboard:=SaveZIP
	
	if(SaveZIP!="" && SaveZIP!=" ")
	{
		SB_SetText("Exporting to " . SaveZIP)
		RunWait, tar -cf "%SaveZIP%" *,%SGfolder%, Min					;Export/backup current keybinds
		
		IfExist, %SaveZIP%												;Confirm backup is created
		{
			SB_SetText("Done. Exported to " . SaveZIP)
			MsgBox,64,Done,Current keybinds exported to:`n`n%SaveZIP%,5
		}
		Else
		{
			SB_SetText("Error, Export failed" . SaveZIP)
			MsgBox,16,Error, Export failed`n`n%SaveZIP%
		}
	}
	else SB_SetText("Exporting cancelled")
return
;=========================================================
;=========================================================
;=========================================================
AutoExport:
	;MsgBox,	FileSelectFile, SaveZIP,2,%Backup%1234.zip
	SB_SetText("Auto backup... ")
	FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss					;Change timestamp format here
	SplitPath, Backup,,ExportLocation
	FileSelectFile, SaveZIP,S2,%ExportLocation%\Undo_%TimeString%.zip,Choose auto backup location,*.zip
	Clipboard:=SaveZIP
	
	if(SaveZIP!="" && SaveZIP!=" ")
	{
		SB_SetText("Exporting to " . SaveZIP)
		RunWait, tar -cf "%SaveZIP%" *,%SGfolder%, Min					;Auto backup current keybinds before importing, just in case
		
		IfExist, %SaveZIP%												;Confirm backup is created
		{
			SB_SetText("Auto backup...Done. Exported to " . SaveZIP)
			;MsgBox,64,Done,Current keybinds exported to:`n`n%SaveZIP%,5
			Sleep, 500
		}
		Else
		{
			SB_SetText("Error, Export failed" . SaveZIP)
			MsgBox,16,Error, Export failed`n`n%SaveZIP%
		}
	}
	else SB_SetText("Exporting cancelled")
return
;=========================================================
;=========================================================
;========================================================= Help text
Help:
HelpText=
(
Set Target input to the folder to be modified:

Default OB =
C:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input

                      <OR>

Default Stable =
C:\Users\%A_Username%\Saved Games\DCS\Config\Input

If you have moved your Saved Games folder to a different location, choose that instead

========================================

Set Backup folder to preferably a separate drive

========================================

Ensure your devices are connected to your PC to detect current UUID
)
	MsgBox,	%HelpText%
return
;=========================================================
;=========================================================
;=========================================================
