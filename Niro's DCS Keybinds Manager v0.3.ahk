;Needs older AHK v1.1
;Script ver 0.3b
;=========================================================
#NoEnv 							; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.
DetectHiddenWindows, On
#SingleInstance, Force

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

Gui, Add, ListView, x0 y110 r20 w900, Name|Old UUID|New UUID
LV_ModifyCol(1,400)
LV_ModifyCol(2,250)
LV_ModifyCol(3,240)

Gui, Add, StatusBar,, 


Gui, Add, Button, gRescan w180 h50 x10 y50, Rescan
Gui, Add, Button, gImport Default w180 h50 x350 y50, <---- Import
Gui, Add, Button, gExport w180 h50 x720 y50, Backup ---->
Gui, Show,,Niro's DCS Keybinds Manager

return

;=========================================================
;=========================================================
;=========================================================
Rescan:

SB_SetText("Searching...")
Sleep,1000
LV_Delete()
modules:=""
repl := []					;Old name, New name
i:=0						;No. of devices
devices:=""

;=========================================================
Loop, %SGfolder%\*,2					;Loop through each module
{
	curr_mod:=A_LoopFileName
	modules=%modules%%curr_mod%`n
	
	;MsgBox,	%modules%
	
	Loop, %SGfolder%\%curr_mod%\joystick\*.diff.lua			;Loop through each device
	{
		If(A_LoopFileName!="" && !Instr(A_LoopFileName,"vJoy"))
		{
			RegexMatch(A_LoopFileName,"O)(.*) (\{.*\})",Match)
			dev_name := % Match[1]
			new_UUID := % Match[2]
			;MsgBox,	%dev_name%`n%new_UUID%
			
			;Check for backup file for this specific device
			Loop,%Backup%\%curr_mod%\joystick\%dev_name%*.diff.lua
			{
				If(A_LoopFileName!="" && !Instr(A_LoopFileName,"vJoy"))
				{
					;MsgBox, Found %A_LoopFileName%`n`n%Backup%\%curr_mod%\joystick\%A_LoopFileName%`n`n%SGfolder%\%curr_mod%\joystick\%dev_name% %new_UUID%.diff.lua
					RegexMatch(A_LoopFileName,"O)(.*) (\{.*\})",Match)
					old_dev_name := % Match[1]
					old_UUID := % Match[2]
					
					If(!Instr(devices,dev_name))
					{
						devices=%devices%%dev_name%`n
						;Store new and old UUID as key-value pair
						repl[old_UUID] := new_UUID
						i:=i+1
						LV_Add("",dev_name,old_UUID,new_UUID)
						SB_SetText("Searching..." . i . " devices found")
					}
				}
			}
		}
	}	
}
;=========================================================

LV_ModifyCol(1,"Sort Text")

if(!i)
{
	SB_SetText("No devices found. [Add atleast one keybind per device] in DCS or [clear binds for each device] in [any one module] to create the required LUA files with new UUID")
	MsgBox,	No matching devices found in target folder. `n`nDefault=`n`nC:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input`n`nOR`n`nC:\Users\%A_Username%\Saved Games\DCS\Config\Input`n`n`n`nIf this is a fresh installation, go to any module and clear the binds for each device and click OK to create required LUAs with new UUID
}else
{
	SB_SetText(i . " devices found. Ready to import")
}

If(devices!="" && 0)
	MsgBox,	Found matching binds for %i% devices:`n`n%devices%

return

Esc::ExitApp

;=========================================================
;=========================================================
;=========================================================
;Replace UUID in filenames
Import:
If(Backup="")
{
	MsgBox,48,Error,Set backup location first to the "Input" folder that contains all the modules
	return
}

Gosub AutoExport

j:=1					;No. of LUA's imported
k:=0					;No. of modules found

SB_SetText("Importing...")
Sleep,500
;MsgBox,	%j%

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
	
	;Copy keyboard, mouse and modifiers binds
	FileCopyDir, %Backup%\%curr_mod%\keyboard\, %SGfolder%\%curr_mod%\keyboard\, 1
	FileCopyDir, %Backup%\%curr_mod%\mouse\, %SGfolder%\%curr_mod%\mouse\, 1		
	FileCopy, %Backup%\%curr_mod%\modifiers.lua, %SGfolder%\%curr_mod%\modifiers.lua, 1	
}	

j:=j-1
SB_SetText("`t>> Replacing UUID inside files, please wait <<")

;=========================================================
;=========================================================
;Replace UUID in file content
l:=""
Loop, Files, %SGfolder%\modifiers.lua, FR					;Loop through all .lua
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
SB_SetText(j . " LUA's imported successfully for " . i . " devices across " . k . " modules")
if(j)
	MsgBox,64,Success!,	%j% LUA's imported successfully for %i% devices across %k% modules,15
else
	MsgBox,64,Niro's DCS Keybinds Manager,No devices found`n`nManually add atleast >one keybind for each device< in DCS to create the required LUA files`n`nYou need to do this for one module only
return

;=========================================================
;=========================================================
;=========================================================
TargetFolder:
	FileSelectFolder, SG2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select DCS Saved Game profile folder to be modified
	if(SG2 != "")
	{
		GuiControl,, Target, %SG2%
		SGfolder:=SG2
		Goto Rescan
	}
return

;=========================================================
;=========================================================
;=========================================================
BackupFolder:
	FileSelectFolder, BK2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select Backup location to import from
	if(BK2 != "")		
	{
		GuiControl,, Bk, %BK2%
		Backup:=BK2
		Goto Rescan
	}
return

;=========================================================
;=========================================================
;=========================================================
Export:
	;MsgBox,	FileSelectFile, SaveZIP,2,%Backup%1234.zip
	SB_SetText("Exporting... ")
	FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss
	SplitPath, Backup,,ExportLocation
	FileSelectFile, SaveZIP,S2,%ExportLocation%\DCS_%TimeString%.zip,Choose export location,*.zip
	Clipboard:=SaveZIP
	
	if(SaveZIP!="" && SaveZIP!=" ")
	{
		SB_SetText("Exporting to " . SaveZIP)
		RunWait, tar -cf "%SaveZIP%" *,%SGfolder%, Min
		
		IfExist, %SaveZIP%
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
	FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss
	SplitPath, Backup,,ExportLocation
	FileSelectFile, SaveZIP,S2,%ExportLocation%\Undo_%TimeString%.zip,Choose auto backup location,*.zip
	Clipboard:=SaveZIP
	
	if(SaveZIP!="" && SaveZIP!=" ")
	{
		SB_SetText("Exporting to " . SaveZIP)
		RunWait, tar -cf "%SaveZIP%" *,%SGfolder%, Min
		
		IfExist, %SaveZIP%
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
;=========================================================
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
)
	MsgBox,	%HelpText%
return
;=========================================================
;=========================================================
;=========================================================
