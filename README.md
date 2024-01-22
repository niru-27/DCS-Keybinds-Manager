
# DCS Keybinds Manager
* Backup &amp; Import your keybinds even after UUID changes (different USB port/Windows reinstall)
* Share you keybinds with others who have the same device as you

## The problem:
Since you can connect multiple joysticks of the same model and use them independently of each other, there needs to be a way to differentiate between them. Windows does this by assigning a random/unique [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) to a device to a USB port. DCS saves keybinds on a per module, per device basis under
`Saved Games\DCS.openbeta28MT\Config\Input\<module>\joystick\`
folder in files named `<Device name> {UUID}.diff.lua`
E.g.: `UFC {9A230490-1324-11ED-8001-444553540000}.diff.lua`

If you plug the same device into another port, it will get a new UUID. So if the UUID doesn't match, your previous keybinds won't load, and you get the default binds only.
E.g.: `UFC {9A230490-1324-11ED-8002-444553540000}.diff.lua`

---
## The solution:
Assuming you have access to the old working keybind files, if you replace the Old UUID with the new UUID in file names, then DCS will load your keybinds.
You also need to replace the UUID inside the `modifiers.lua` file for each module.

Now if you have only a couple of devices and a couple of modules, this is easy enough to do manually using programs like:
* [Bulk Rename Utility](https://www.bulkrenameutility.co.uk/)'s Renaming From A Text File feature
	>to change file names
* [Notepad++](https://notepad-plus-plus.org/)'s Find in Files feature
	>to search & replace Old UUID with New UUID inside the files

But if you have a lot of devices and a lot of modules (FC3 alone will have 9 modules with separate keybinds for each), even this becomes a tedious process.

---
## The better solution:
DCS Keybinds Manager is an [AutoHotKey](https://www.autohotkey.com/) script that will perform the above steps in one click. All you need to do is tell it where the backup folder is located. It will scan and list all devices that have keybinds available under a different UUID in the backup.
Hit Import and it will:
* automatically backup current keybinds in case something goes wrong.
* copy `<Device name> {Old UUID}.diff.lua` files from backup folder to `<Device name> {New UUID}.diff.lua`
* Replace all references to `{Old UUID}` with `{New UUID}` in LUA file content so that modifiers will work

It will also allow you to **Backup current keybinds** to a time stamped zip file for safe keeping, which you can Import at a later time if required, or share with others.

---
# Installation
1. This script is written for [AutoHotKey](https://www.autohotkey.com/) v1.1, and won't run in the newer v2.0. If you're familiar with AHK, you can convert the script yourself to work with v2
2. Download the latest release and extract it somewhere on your PC
3. Connect all your peripherals
4. Run `Niro's DCS Keybinds Manager.ahk`

---
# Usage:
## v0.4-beta: should auto detect new UUIDs of connected devices, thanks to evilC's JoystickWrapper library https://github.com/evilC/JoystickWrapper

## Important:
If the script can't detect connected devices and show it as 0, you need to unblock the DLL files you downloaded with the script
> You can do it manually by Right Clicking each DLL file > Properties > check Unblock > Apply
>  ![unblock1](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/1c1a5480-b9ec-4528-a4d3-7e9c698df0c8)
>  ![unblock2](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/b3463f37-cca7-4e77-9c9e-a7974528b717)
>  ![unblock3](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/fb8f3512-70ce-4d98-b545-078366f98f28)
>  ![unblock4](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/244ce6a2-1d2f-4a5c-817b-acc37121429f)


## Setup folder paths
1. Target Saved Games folder should auto detect for OpenBeta. You can click on the button to select manually if required, or you can copy paste the path into the textbox
![1](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/bd403b08-f2a4-43ef-9040-2bdb01d3aac0)
2. Select Backup path where you previously backed up your `Inputs` folder
3. Ensure your devices are detected
4. A list of matching UUIDs should populate, if not hit `Rescan`
![2](https://github.com/niru-27/DCS-Keybinds-Manager/assets/41210892/8c9eabbc-96af-4970-a792-300ccc84a73f)
5. If there are no matches, ensure all your devices are connected and unblock the DLL files


---
## Importing:
* You can import a previously made backup, like if you copied your keybinds folder somewhere.
* To import a backup made using this utility, extract the zip into a new folder, and select that folder as the Backup location

1. Run `Niro's DCS Keybinds Manager.ahk` on your PC
2. The default target folder should be `...\Saved Games\DCS.openbeta\Config\Input`
	>If you need to select a different folder, click on the button and browse. You can change the default Target path in the script if required
3. Click `Backup "Input" Folder` button & browse to the location of your backup folder. For e.g. `D:\Backup\DCS_2024-01-01_12-34-56`
	> This is the folder that contains all the module folders like `A-10C II`, `FA-18C_hornet`, `J-11A`, etc. You can change the default Backup path in the script required
4. Click `Rescan` and the script will scan both Target & Backup folders to figure out matching LUA files based on Device Name
	> If you have more than one device with the same name, this script won't work and you have to manually import them
5. Click `Import`. You will be asked to backup current binds "just in case,"
>Press `Enter` to save the backup zip which will let you undo the import if required

>All matching devices from the Backup location will be then imported

6. Start DCS to see the imported binds

---
## Backing Up:
1. Click the `Backup` button
2. Browse to save location. By default it will be the parent folder of the specified `Backup "Input" Folder`
3. The default filename will be `DCS_YYYY`-`MM`-`DD`_`HH`-`mm`-`ss`.zip
	> This time format will let you sort the files alphabetically, so the latest backup will be at the bottom. You can change it as required in the script
4. Click the `Save` button to generate the backup zip
5. You can copy the backup ZIP to the cloud for safekeeping, or share with others if they have the same devices as you

---
## Known issues:
Investigating: VKB devices may not appear in the list, but are imported nevertheless. Having a leading space in their device name seems to be the culprit. When extracting saved binds, right click the zip and select Extract to ____ folder instead of Drag & Drop to avoid problems

Todo: Confirm XBox controller UUID is detected properly

Fixed: ~~Clicking the close button leaves the script running, so please press Escape or close it from system try when you're done~~
Fixed: ~~If you don't have 7zip or another compression software, Windows explorer was unable to open the backup archive created using Window's own tar.exe utility. Your old archives are perfectly safe.~~
