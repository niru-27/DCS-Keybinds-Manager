;Needs older AHK v1.1
version=0.96b
;No need to manually create LUAs via DCS. Should auto detect UUIDs thanks to evilC's JoystickWrapper library
;https://github.com/evilC/JoystickWrapper
;Download above library and put the DLL and AHK files next to this script
;Get latest version from: https://github.com/niru-27/DCS-Keybinds-Manager
;=========================================================
#NoEnv 							; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.
DetectHiddenWindows, On
#SingleInstance, Force
Menu, Tray, Icon, Shell32.dll, 45
#Include JoystickWrapper.ahk
global jw := new JoystickWrapper("JoystickWrapper.dll")

SGvalid:=0					;Saved Games path valid
BackupValid:=0				;Backup path valid
DEVvalid:=0					;Currently connected devices detected
;=========================================================
;Path to target DCS Saved Games Folder to be MODIFIED
SGfolder = C:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input
;SGfolder = E:\Mine\Saved Games\DCS.openbeta\Config\Input

;=========================================================
;Path to BACKUP source folder. Will never be modified
Backup=
;Backup=E:\test\Input
;=========================================================
;=========================================================
;=========================================================
;Set icons depending on Windows 10 or 11
; Set the registry key path
RegPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

; Read the Settings binary value from the registry
RegRead, SettingsValue, % RegPath, Settings
;MsgBox, SettingsValue %SettingsValue%
; Extract the 9th byte from the binary value
NinthByte := SubStr(SettingsValue, 17, 1)
;MsgBox, NinthByte %NinthByte%
; Check if the 9th byte indicates auto-hide is enabled (03)
if (NinthByte = "0")
{
	winVersion := 10
	greentick:=297
	alert:=78
}
else if (NinthByte = "7")
{
	winVersion := 11
	greentick:=301
	alert:=78
}
else
{
	winVersion := A_OSVersion
}
;=========================================================
;=========================================================
;=========================================================

;Gui, New,,Niro's DCS Keybinds Manager

Gui, Add, Button, gHelp x438 y10 w35 h35 hwndIcon3,
GuiButtonIcon(Icon3, "shell32.dll", 155, "s25")
;=========================================================
Gui, Add, Button, gTargetFolder x10 y10 w100 h30 hwndIcon1, Target "Input" Folder
Gui, Add, Edit, x115 y15 w320 vTarget gChkPathSG, %SGfolder%

IfExist,%SGfolder%
{
	GuiButtonIcon(Icon1, "shell32.dll", greentick, "s20 a0 t4")
	SGvalid:=1
}
Else
{
	GuiButtonIcon(Icon1, "shell32.dll", alert, "s20 a0 t4")
	SGvalid:=0
}
;=========================================================
Gui, Add, Edit,x475 y15 w320 vBk Right gChkPathBk, %Backup%
Gui, Add, Button, gBackupFolder x800 y10 w100 h30 hwndIcon2, Backup "Input" Folder
;GuiButtonIcon(Icon2, "shell32.dll", 78, "s20 a0 b2")

IfExist,%Backup%
{
	BackupValid:=1
	GuiControl,, Bk, %Backup%
	GuiButtonIcon(Icon2, "shell32.dll", greentick, "s20 a0 t4")
}
Else
{
	GuiButtonIcon(Icon2, "shell32.dll", alert, "s20 a0  l2 b2")
	BackupValid:=0
}	
;=========================================================

Gui, Add, ListView, x10 y110 r20 w900 +Background0xdcdcd9, Device Name|Current UUID|Old UUID

LV_ModifyCol(1,400)
LV_ModifyCol(2,250)
LV_ModifyCol(3,240)

Gui, Add, StatusBar,, 

Gui Font, s15, Verdana
Gui, Add, Button, gRescan w180 h50 x10 y50 hwndIcon4, Rescan
GuiButtonIcon(Icon4, "shell32.dll", 210, "s48 a0 l20")

Gui, Add, Button, gImport w180 h50 x370 y50 hwndIcon5,<-- Import
GuiButtonIcon(Icon5, "shell32.dll", 27, "s48 a0 l2 b5")

Gui, Add, Button, gExport w180 h50 x720 y50 hwndIcon6, Backup -->
GuiButtonIcon(Icon6, "shell32.dll", 259, "s40 a1 r10 b2")

Gui, Font, s10 Bold
Gui Add, Text, x207 y50 w150 h23 +0x200 Center, Connected devices:
Gui, Font, s15 q5
Gui Add, Text, x207 y73 w150 h23 +0x200 Center c33ff33 vNODg,
Gui Add, Text, x207 y73 w150 h23 +0x200 Center cff3333 vNODr,

;=========================================================
GoSub RefreshDevices

Gui, Font,
Gui, Color, aaaaaa

;Green tick = 297	303
;Right arrow = 300
;Exclamation = 78

Gui, Show,,Niro's DCS Keybinds Manager - v%version%
return

;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Rescan Button
Rescan:
	Gosub RefreshDevices		;Check new devices
	
	If(!BackupValid)			;Validate Backup path
	{
		SB_SetText("Set Backup location")
		return
	}
	;=========================================================
	If(!SGvalid)				;Validate Target path
	{
		SB_SetText("Set Target location")
		return
	}
	;=========================================================
	If(SGfolder=Backup)
	{
		GuiButtonIcon(Icon1, "shell32.dll", alert, "s20 a0 t4")
		GuiButtonIcon(Icon2, "shell32.dll", alert, "s20 a0 t4")
		MsgBox,48,Error,Target and Backup paths can't be the same!
	}
	else
	{
		GuiButtonIcon(Icon1, "shell32.dll", greentick, "s20 a0 t4")
		GuiButtonIcon(Icon2, "shell32.dll", greentick, "s20 a0 t4")
	}
	;=========================================================
	If(!DEVvalid)				;Validate devices are connected
	{
		SB_SetText("Connect your devices to detect their current UUID. Make sure DLL files are unblocked to enable detection")
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
	DeviceList := jw.GetDevices()				;DirectInput devices

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
			;MsgBox,	%curr_mod%`n>%old_name%<`n%old_UUID%
			
			If(InStr(old_name,"VKBsim") && !InStr(old_name," VKBsim"))					;Handle missing leading space
			{
				old_name:=" " . old_name
			}
			
			;Joysticks/DirectInput
			for d, dev in DeviceList
			{
				new_name:=dev.Name
				new_UUID:=dev.Guid
				StringUpper, new_UUID, new_UUID
				new_UUID={%new_UUID%}
				
				;Convert part of UUID to lower case, because "ED"
				;While joystick binds seem unaffected, modifiers are not recognized
				RegexMatch(new_UUID,"O)(\{.*-.*-)(.*)(-.*-.*\})",Match2)
				mod:=% Match2[2]
				StringLower,mod,mod
				new_UUID:=% Match2[1] . mod . Match2[3]		;Rebuild new_UUID
				;MsgBox,%new_UUID%
						
				if(old_name = new_name)
				{
					If(!Instr(devices,old_name) && !Instr(old_name,"vJoy"))
					{
						devices=%devices%>%old_name%<`n
						
						;Store new and old UUID as key-value pair
						repl[old_UUID] := new_UUID
						i:=i+1
						
						;old_name=>%old_name%<
						LV_Add("",old_name,new_UUID,old_UUID)
						SB_SetText("Searching..." . i . " devices found in " . k . " modules")
						;MsgBox,Match found:`n`n%old_name%`n%new_UUID%`n%old_UUID%
						Sleep, 20
					}
				}
			}			
		}
		SB_SetText("Searching..." . i . " devices found in " . k . " modules")
		Sleep, 20
	}
	;MsgBox,	%k% modules found:`n`n%modules%
	;=========================================================
	LV_ModifyCol(1,"Sort Text")					;Sort list alphabetically

	if(!i)
	{
		SB_SetText("No devices found...Check both paths & ensure your devices are connected to your PC to detect current UUID")
		;MsgBox,	No matching devices found between target <--> Backup folders.`n`n1) Verify both paths and try again`n`nDefault OB =`nC:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input`n`n`t<OR>`n`nDefault Stable =`nC:\Users\%A_Username%\Saved Games\DCS\Config\Input`n`n`n2) Ensure your devices are connected to your PC to detect current UUID
		
		Gui, Help:New,,Help

		Gui, Font, s15 w800, Verdana
		Gui, Add, Text, x12 y12 , No matching devices found between Target <--> Backup folders`n`n1) Verify both paths and try again
		Gui, Add, GroupBox, x5 y45 w910 h100 , 

		Gui, Font, s13 w400, Consolas
		Gui, Add, Text, x12 y95, Default OpenBeta = C:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input
		Gui, Add, Text, x12 y120, Default Stable   = C:\Users\%A_Username%\Saved Games\DCS\Config\Input

		Gui, Font, s15 w800, Verdana
		Gui, Add, Text, x12 y160, 2) Set Backup folder to preferably a separate drive
		Gui, Font, s13 w400, Consolas
		Gui, Add, Text, x12 y195, E.g. = D:\Backup\Input

		Gui, Add, Text, , 
		Gui, Font, s15 w800, Verdana
		Gui, Add, Text, x12 y240, 3) Ensure all your devices are connected to your PC to detect their current UUID  

		Gui, Font, s15 w400, Verdana
		Gui, Add, Link,, `n`nMore info in repo <a href="https://github.com/niru-27/DCS-Keybinds-Manager">ReadMe</a>
		Gui, Font, norm
		Gui, Show
		return
	}else
	{
		SB_SetText("Backup found for " . i . " devices in " . k . " modules. Ready to import")
	}

	If(devices!="" && 0)
		MsgBox,	Found matching binds for %i% devices:`n`n%devices%

return

;=========================================================
#IfWinActive, Niro's DCS Keybinds Manager - v ahk_class AutoHotkeyGUI ahk_exe AutoHotkey.exe
GuiClose:
Esc::ExitApp
#IfWinActive
;=========================================================
;=========================================================
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Import button
Import:
	;MsgBox,	%SGvalid% %BackupValid% %DEVvalid%

	If(!SGvalid)				;Validate Target path
	{
		SB_SetText("Set Target location")
		return
	}
	If(!BackupValid)			;Validate Backup path
	{
		SB_SetText("Set Backup location")
		return
	}
	If(!DEVvalid)				;Validate devices are connected
	{
		SB_SetText("Connect your devices to detect their current UUID")
		return
	}

	Gosub AutoExport		;Backup first in case you want to undo later

	Gosub Rescan			;Refresh devices

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
		SB_SetText("Importing... " . curr_mod)
		
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
	SB_SetText("`t>> Replacing UUID inside files, please wait ... <<")

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

;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Set Saved Games/Target folder button
TargetFolder:
	FileSelectFolder, SG2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select DCS Saved Game profile folder to be modified
	if(SG2 != "")
	{
		IfExist,%SG2%					;Validate selected Target SG path
		{
			SGvalid:=1
			GuiControl,, Target, %SG2%
			SGfolder:=SG2
			GuiButtonIcon(Icon1, "shell32.dll", greentick, "s20 a0 t4")
			
			;Goto Rescan
		}
		Else
		{
			SGvalid:=0
			GuiButtonIcon(Icon1, "shell32.dll", alert, "s20 a0 t4")
			SB_SetText("Set Target location first")
		}
	}
return

;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Set Backup folder button
BackupFolder:
	FileSelectFolder, BK2, ::{20d04fe0-3aea-1069-a2d8-08002b30309d},2, Select Backup location to import from
	if(BK2 != "")		
	{
		IfExist,%BK2%					;Validate selected Backup path
		{
			BackupValid:=1
			GuiControl,, Bk, %BK2%
			Backup:=BK2
			GuiButtonIcon(Icon2, "shell32.dll", greentick, "s20 a0 t4")
			
			;Goto Rescan
		}
		Else
		{
			BackupValid:=0
			GuiButtonIcon(Icon2, "shell32.dll", alert, "s20 a0 t4")
		}		
	}
	else SB_SetText("Set Backup location first")
return

;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Export button
Export:
	
		ii:=0
		Loop,Files,%SGfolder%\*,D					;Ensure Target Input folder is not empty
		{
			ii:=ii+1
			;MsgBox,	%A_LoopFileName%
		}
		;MsgBox, %ii%`n`n%SGfolder%
		
		if(ii>0)
		{
			SB_SetText("Exporting... ")
			FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss					;Change timestamp format here
			SplitPath, Backup,,ExportLocation
			FileSelectFile, SaveZIP,S2,%ExportLocation%\DCS_%TimeString%.zip,Choose export location,*.zip
			Clipboard:=SaveZIP
			
			if(SaveZIP!="" && SaveZIP!=" ")
			{
				SB_SetText("Exporting to " . SaveZIP)
				RunWait, tar -caf "%SaveZIP%" *,%SGfolder%, Min					;Export/backup current keybinds
				
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
		}
		else
		{
			SB_SetText("No current binds. Skipping export")
			MsgBox,48,Error, Nothing to export. Target folder is empty`n`n%SGfolder%
			Sleep, 1000
		}
return
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
AutoExport:
	If(!BackupValid)			;Validate Backup path
	{
		SB_SetText("Set Backup location")
		return
	}	
	
	IfExist, %SGfolder%
	{
		ii:=0
		Loop,Files,%SGfolder%\*,D					;Ensure Target Input folder is not empty
			ii:=ii+1
		;MsgBox, %ii%`n`n%SGfolder%
		;MsgBox, Nothing to export. Folder is empty`n`n%SGfolder%
		
		if(ii)
		{	
			SB_SetText("Auto backup... ")
			FormatTime, TimeString, A_Now, yyyy-MM-dd_HH-mm-ss					;Change timestamp format here
			SplitPath, Backup,,ExportLocation
			FileSelectFile, SaveZIP,S2,%ExportLocation%\Undo_%TimeString%.zip,Choose auto backup location,*.zip
			Clipboard:=SaveZIP
			
			if(SaveZIP!="" && SaveZIP!=" ")
			{
				SB_SetText("Exporting to " . SaveZIP)
				RunWait, tar -caf "%SaveZIP%" *,%SGfolder%, Min					;Auto backup current keybinds before importing, just in case
				
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
		}
		else
		{
			SB_SetText("No current binds to backup. Skipping auto export")
			Sleep, 1000
		}
	}
return
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Help Button
Help:
	Gui, Help:New,,Help

	Gui, Add, GroupBox, x5 y5 w910 h110 , 

	Gui, Font, s15 w800, Verdana
	Gui, Add, Text, x12 y12 , 1) Set Target input to the folder to be modified:

	Gui, Font, s13 w400, Consolas
	Gui, Add, Text, x12 y50, Default OpenBeta = C:\Users\%A_Username%\Saved Games\DCS.openbeta\Config\Input
	Gui, Add, Text, x12 y80, Default Stable   = C:\Users\%A_Username%\Saved Games\DCS\Config\Input

	Gui, Font, s15 w800, Verdana
	Gui, Add, Text, x12 y150, 2) Set Backup folder to preferably a separate drive
	Gui, Font, s13 w400, Consolas
	Gui, Add, Text, x12 y185, E.g. = D:\Backup\Input

	Gui, Add, Text, , 
	Gui, Font, s15 w800, Verdana
	Gui, Add, Text, x12 y240, 3) Ensure all your devices are connected to your PC to detect their current UUID
	Gui, Font, s13 w400, Consolas
	Gui, Add, Text, x12 y275, Only devices with the same name can be matched and imported
	Gui, Add, Text, x12 y300, If no devices are detected, unblock all 4 DLL files manually
	Gui, Add, Text, x12 y320, Right click > Properties > Unblock > Apply > OK
	;Gui, Add, Text, x12 y350, Else run the Unblock script as Admin to do it automatically

	Gui, Font, s15 w400, Verdana
	Gui, Add, Link,, `n`nMore info in repo <a href="https://github.com/niru-27/DCS-Keybinds-Manager">ReadMe</a>
	Gui, Font, norm
	Gui, Show
return



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
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Get current device UUID using JoystickWrapper
RefreshDevices:
	global DeviceList := jw.GetDevices()				;DirectInput devices
	
	LV_Delete()

	i:=0						;No. of devices
	;Joysticks/DirectInput
	for d, dev in DeviceList
	{
		If(!Instr(dev.name,"vJoy"))
		{
			i:=i+1
			new_UUID:=dev.Guid
			StringUpper, new_UUID, new_UUID
			LV_Add("",dev.Name,new_UUID,"")			
		}
	}
	;=========================================================
	;MsgBox,	%i%
	if(i)
	{
		SB_SetText( i . " connected devices detected")
		
		GuiControl,Hide,NODr
		GuiControl,,NODg, %i%
		GuiControl,Show,NODg					;Show device count in Green

		DEVvalid:=1
	}
	else
	{
		SB_SetText( "No devices detected. Please connect all the peripherals you want to import")
		
		GuiControl,Hide,NODg
		GuiControl,,NODr, %i%
		GuiControl,Show,NODr					;Show device count in Red

		DEVvalid:=0
	}
	
	LV_ModifyCol(1,"Sort Text")					;Sort list alphabetically
return
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;Button icons
GuiButtonIcon(Handle, File, Index := 1, Options := "")
{
	RegExMatch(Options, "i)w\K\d+", W), (W="") ? W := 16 :
	RegExMatch(Options, "i)h\K\d+", H), (H="") ? H := 16 :
	RegExMatch(Options, "i)s\K\d+", S), S ? W := H := S :
	RegExMatch(Options, "i)l\K\d+", L), (L="") ? L := 0 :
	RegExMatch(Options, "i)t\K\d+", T), (T="") ? T := 0 :
	RegExMatch(Options, "i)r\K\d+", R), (R="") ? R := 0 :
	RegExMatch(Options, "i)b\K\d+", B), (B="") ? B := 0 :
	RegExMatch(Options, "i)a\K\d+", A), (A="") ? A := 4 :
	Psz := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"
	VarSetCapacity( button_il, 20 + Psz, 0 )
	NumPut( normal_il := DllCall( "ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1 ), button_il, 0, Ptr )	; Width & Height
	NumPut( L, button_il, 0 + Psz, DW )		; Left Margin
	NumPut( T, button_il, 4 + Psz, DW )		; Top Margin
	NumPut( R, button_il, 8 + Psz, DW )		; Right Margin
	NumPut( B, button_il, 12 + Psz, DW )	; Bottom Margin	
	NumPut( A, button_il, 16 + Psz, DW )	; Alignment
	SendMessage, BCM_SETIMAGELIST := 5634, 0, &button_il,, AHK_ID %Handle%
	return IL_Add( normal_il, File, Index )
}
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
ChkPathSG:
	Gui Submit, NoHide
	
	IfExist,%Target%					;Validate selected Target SG path
	{
		SGvalid:=1
		;GuiControl,, Target, %SG2%
		SGfolder:=Target
		GuiButtonIcon(Icon1, "shell32.dll", greentick, "s20 a0 t4")
		
		if BackupValid
			SB_SetText("Press Rescan to search for matching keybinds")
		else
			SB_SetText("Target location valid. Set Backup location")
	}
	Else
	{
		SGvalid:=0
		GuiButtonIcon(Icon1, "shell32.dll", alert, "s20 a0 t4")
		SB_SetText("Target location not valid")
	}
return
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
ChkPathBk:
	Gui Submit, NoHide
	
	IfExist,%Bk%					;Validate selected Target SG path
	{
		BackupValid:=1
		;GuiControl,, Target, %SG2%
		Backup:=Bk
		GuiButtonIcon(Icon2, "shell32.dll", greentick, "s20 a0 t4")
		
		if SGvalid
			SB_SetText("Press Rescan to search for matching keybinds")
		else
			SB_SetText("Backup location valid. Set Target location")
	}
	Else
	{
		BackupValid:=0
		GuiButtonIcon(Icon2, "shell32.dll", alert, "s20 a0 t4")
		SB_SetText("Backup location not valid")
	}
return

;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================
;==================================================================================================================