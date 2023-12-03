# DCS Keybinds Manager
Backup &amp; Import your keybinds even after UUID changes (different USB port/Windows reinstall)

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
* copy `<Device name> {Old UUID}.diff.lua` files from backup folder to `<Device name> {New UUID}.diff.lua`
* Replace all references to `{Old UUID}` with `{New UUID}` in LUA file content so that modifiers will work

It will also allow you to **Backup current keybinds** to a time stamped zip file for safe keeping, which you can Import at a later time if required, or share with others.
