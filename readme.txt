 ************************************************************************************************************

  Game Save Manager for Infinifactory
  
  V1.4.0 / 2015-03-25

  © 2015 - Kronzky (kronzky@gmail.com / www.kronzky.info/other/infinisaver)
  
  GitHub repo: https://github.com/Kronzky/InfiniSaver

 **********************************************************************************************

  INSTALLATION:
  	Create a new folder, and copy the InfiniSaver.exe and .ini into it.


  USAGE:
	Start InfiniSaver, and it will look in My Documents\My Games\Infinifactory\
	for any existing game saves. If your save location is elsewhere, click on the
	'Select' button, and go to the folder that contain the save.dat file 
	(the folder name will normally be a very long number).
	
	All available solutions will be listed, with their internal name, their title,
	and the current scores (cycles/footprint). If a solution has not been completed
	yet, it will show "WiP" in the save slot column.
	
  * Copy between slots
	To copy a save from one slot to another, select the appropriate level, and choose
	the 'from' and 'to' slots from the drop-down menus at the bottom.
	Click 'Copy', and the solution will be copied.
	
  * Copy to/from harddrive
	To save a solution to the harddrive, select the source slot, and in the 'to' menu
	select 'Harddrive'. Once you click 'Copy' you will be prompted for a name. Be aware
	that you do NOT need to add any level identified to this name, as that will be added
	automatically when the file is saved. 
	
	To restore a solution from the hardrive, select the appropriate filename in the
	'from' menu (only the compatible saves will be shown), select the target slot, 
	and click 'Copy'.
	
  * Save/restore full game saves
	Click 'Create Backup' to copy the complete save file to the harddrive (the name schema
	is "save_yyyymmdd-hhmm.dat".
	To load a backup from the harddrive, click 'Restore Backup' and select the desired
	file.

  * Save/restore key shortcuts
	Key shortcuts can be saved and restored independently from the main or level saves 
	via the 'Backup/Restore Key Shortcuts' buttons.
	
  *	Block count and efficiency calculation
    When hovering over a save slot, a tooltip will show the cycle and footprint value,
	as well as the number of blocks used, and an efficiency calculation.
	The formula for this calculation is stored in the InfiniSaver.ini file, 
	and can be modified by the user.

	
	All save files (for the complete game or individual levels) will be stored in the
	same folder that the InfiniSaver program in installed in.
		

             
 **********************************************************************************************
     
