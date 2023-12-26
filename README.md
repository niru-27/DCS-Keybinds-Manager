
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

## The solution:
Assuming you have access to the old working keybind files, if you replace the Old UUID with the new UUID in file names, then DCS will load your keybinds.
You also need to replace inside the `modifiers.lua` file for each module.

Now if you have only a couple of devices and a couple of modules, this is easy enough to do manually using programs like:
* [Bulk Rename Utility](https://www.bulkrenameutility.co.uk/)'s Renaming From A Text File
	>to change file names
* [Notepad++](https://notepad-plus-plus.org/)'s Find in Files
	>to search & replace Old UUID with New UUID inside the files

But if you have a lot of devices and a lot of modules (FC3 alone will have 9 moules with separate keybinds for each), even this becomes a tedious process.

## The better solution:
DCS Keybinds Manager is an [AutoHotKey](https://www.autohotkey.com/) script that will perform the above steps in one click. All you need to do is tell it where the backup folder is located. It will scan and list all devices that have keybinds available under a different UUID in the backup.
Hit Import and it will:
* automatically backup current keybinds in case something goes wrong.
* copy `<Device name> {Old UUID}.diff.lua` files from backup folder to `<Device name> {New UUID}.diff.lua`
* Replace all references to `{Old UUID}` with `{New UUID}` in LUA file content so that modifiers will work

It will also allow you to **Backup current keybinds** to a time stamped zip file for safe keeping, which you can Import at a later time if required, or share with others.


# Installation
1. This script is written for [AutoHotKey](https://www.autohotkey.com/) v1.1, and won't run in the newer v2.0. If you're familiar with AHK, you can convert the script yourself
2. Download the AHK script file from this repo and save it on your PC

# Usage
## If you just reinstalled Windows, you will have a fresh DCS Saved Games folder, with no LUA files. To create those files, you need to :
1. Start DCS
2. Goto Settings > Controls
3. Bind one button per device, for all the devices, under just one module (doesn't matter which, just that all devices have to be bound)
OR
Clear the binds for each device under any one module
4. Click OK to create fresh LUAs with new UUIDs

## Importing:

1. Run the AHK file on your PC
2. The default target folder should be `...\Saved Games\DCS.openbeta\Config\Input`
	>If you need to select a different folder, click on the button and browse. You can change the default Target path in the script if required
3. Click `Backup "Input" Folder` button & browse to the location of your backup folder. For e.g. `D:\Backup\Input`
	> This is the folder that contains all the module folders like `A-10C II`, `FA-18C_hornet`, `J-11A`, etc. You can change the default Backup path in the script required
4. The script should auto scan both Target & Backup folders to figure out matching LUA files based on Device Name
	> If you have more than one device with the same name, this script won't work and you have to manually import them
5. Click `Import` to save current binds "just in case" and import all the matching devices from the Backup location

## Backing Up:
1. Click the Backup button
2. Select folder save location. By default it will be the parent folder of the specified `Backup "Input" Folder`
3. By default, the filename will be `DCS_YYYY`-`MM`-`DD`_`HH`-`mm`-`ss`.zip
	> This time format will let you sort the files alphabetically. You can change it as required in the script
4. Click the `Save` button
5. You can backup the timestamped ZIP to the cloud, or share with others if they have the same devices as you
