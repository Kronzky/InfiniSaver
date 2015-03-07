#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=infinisaver.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <Date.au3>
#Include <Misc.au3>
#Include <Array.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <WindowsConstants.au3>


$saveRoot = @UserProfileDir & "\My Documents\My Games\Infinifactory\"
$savePath = $saveRoot

$iniFile = @WorkingDir & "\InfiniSaver.ini"
If FileExists($iniFile) Then
	$savePath = IniRead($iniFile,"general","path",$savePath)
	$saveRoot = StringLeft($savePath,StringInStr($savePath,"\",0,-1)-1)
	DebugPrint($saveRoot)
Else
	If FileExists($saveRoot) Then
		$folders = _FileListToArray($saveRoot)
		$newestFolder = ""
		$newestDate = ""
		For $i=1 To $folders[0]
			$folder = $folders[$i]
			$date = FileGetTime($saveRoot & $folder & "\save.dat",0,1)
			If $date>$newestDate Then
				$newestDate = $date
				$newestFolder = $folder
			EndIf
			;DebugPrint($saveRoot & $folder & ": " & $date)
		Next
		$savePath = $saveRoot & $newestFolder
	EndIf
EndIf



;==================================================================

Func DebugPrint($msg)
    ConsoleWrite($msg & @CRLF)
    DllCall("kernel32.dll", "none", "OutputDebugString", "str", "[K] " & $msg)
EndFunc

Func GetTitle ($path,$level)
	$lvlHdl = FileOpen($path & "\workshop\" & $level)
	$title = ""
	While 1
		$line = FileReadLine($lvlHdl)
		If @error Then ExitLoop
		If StringLeft($line,5)=="Title" Then
			$title = StringMid($line,8)
			ExitLoop
		EndIf
	WEnd
	FileClose($lvlHdl)
	Return $title
EndFunc

Func GetLevels($path,$list)
	_GUICtrlListView_DeleteAllItems($list)
	Global $savedLevels[1][11] ; [levelID,title, slot1:cycles,slot2:cycles,slot3:cycles, slot1:footprint,slot2:footprint,slot3:footprint, slot1:solution,slot2:solution,slot3:solution]

	$savHdl = FileOpen($path & "\save.dat")

	$level = ""
	$title = ""
	$lastlevel = ""
	$item = 0
	$save1 = "-"
	$save2 = "-"
	$save3 = "-"
	$idx = -1

	While 1
		$line = FileReadLine($savHdl)
		If @error Then ExitLoop

		If StringLeft($line,4)=="Last" Then
			$info = StringSplit(StringStripWS($line,8),".",2)
			$level = $info[1]
			$slot = Number($info[2])
			$result = StringSplit($info[3],"=",2)
			$type = $result[0]
			$idxoff = 2
			If $type = "Footprint" Then $idxoff = 5
			$score = $result[1]


			If $level<>$lastlevel Then
				ReDim $savedLevels[UBound($savedLevels,1)+1][11]
				$savedLevels[UBound($savedLevels,1)-1][0] = $level
				$savedLevels[UBound($savedLevels,1)-1][$idxoff+$slot] = $score
				;DebugPrint("new: " & $level & ", " & $slot & ", " & $type & ", " & $score  & ", " & $idxoff+$slot)
			Else
				$savedLevels[UBound($savedLevels,1)-1][$idxoff+$slot] = $score
				;DebugPrint("old: " & $level & ", " & $slot & ", " & $type & ", " & $score  & ", " & $idxoff+$slot)
			EndIf
			$lastlevel = $level
		EndIf

		If StringLeft($line,8)=="Solution" Then
			$start = StringMid($line,10,1)
			If $start=="w" Or Number($start)>0 Then
				$info = StringSplit($line," ",2)
				$levelinfo = StringSplit($info[0],".",2)
				$level = $levelinfo[1]
				$slot = $levelinfo[2]
				$solution = $info[2]
				If $solution<>"" Then
					$title = "Campaign"
					If $start=="w" Then $title = GetTitle($path,$level)

					If $title<>"" Then
						If $level<>$lastlevel Then
							$idx = -1
							For $i=0 To UBound($savedLevels,1)-1
								$levelId = $savedLevels[$i][0]
								If $levelId==$level Then
									$idx = $i
									$savedLevels[$i][1] = $title
									$savedLevels[$i][8+$slot] = $solution
								EndIf
							Next
							If $idx==-1 Then
								$idx = UBound($savedLevels,1)
								$savedLevels[$idx-1][0] = $level
								$savedLevels[$idx-1][1] = $title
								$savedLevels[$idx-1][8+$slot] = $solution
								ReDim $savedLevels[$idx+1][11]
							EndIf
						Else

						EndIf
					EndIf
					$lastlevel = $levelId
				EndIf
			EndIf
		EndIf
	WEnd
	FileClose($savHdl)


	For $i=1 To UBound($savedLevels,1)-2
		If $savedLevels[$i][1]<>"" Then
			$info = ""
			For $j=0 to 10
				$info &= $savedLevels[$i][$j] & ", "
			Next

			$level = $savedLevels[$i][0]
			$title = $savedLevels[$i][1]
			$save1 = "-"
			If $savedLevels[$i][2]<>"" Then
				$save1 = $savedLevels[$i][2] & "/" & $savedLevels[$i][5]
			Else
				If $savedLevels[$i][8]<>"" Then
					$save1 = "WiP"
				EndIf
			EndIf
			$save2 = "-"
			If $savedLevels[$i][3]<>"" Then
				$save2 = $savedLevels[$i][3] & "/" & $savedLevels[$i][6]
			Else
				If $savedLevels[$i][9]<>"" Then
					$save2 = "WiP"
				EndIf
			EndIf
			$save3 = "-"
			If $savedLevels[$i][4]<>"" Then
				$save3 = $savedLevels[$i][4] & "/" & $savedLevels[$i][7]
			Else
				If $savedLevels[$i][10]<>"" Then
					$save3 = "WiP"
				EndIf
			EndIf
			$idx = _GUICtrlListView_AddItem($list,$i,0)
			_GUICtrlListView_AddSubItem($list, $idx, $level,1)
			_GUICtrlListView_AddSubItem($list, $idx, $title,2)
			_GUICtrlListView_AddSubItem($list, $idx, $save1,3)
			_GUICtrlListView_AddSubItem($list, $idx, $save2,4)
			_GUICtrlListView_AddSubItem($list, $idx, $save3,5)
		EndIf
	Next

EndFunc

Func GetSaves($path)
	$saveHdl = FileOpen($path & "\save.dat")
EndFunc

;==================================================================

$guiWidth = 600
$guiHeight = 590

GUICreate("Infinifactory Save File Editor",$guiWidth, $guiHeight)

GUICtrlCreateLabel ("Save File Folder:",10,20,100)
$fromFile = GUICtrlCreateInput($savePath, 95, 15, 400, 20)

$folderBtn = GUICtrlCreateButton("Select", $guiWidth-100, 15, 80, 20)

$backupBtn = GUICtrlCreateButton("Create Backup", 50, 50, 200, 30)
$restoreBtn = GUICtrlCreateButton("Restore Backup", 350, 50, 200, 30)

$backupKeysBtn = GUICtrlCreateButton("Backup Key Shortcuts", 50, 100, 200, 25)
$restoreKeysBtn = GUICtrlCreateButton("Restore Key Shortcuts", 350, 100, 200, 25)

GUICtrlCreateLabel ("Available Saves:",10,150,100)

$SavList = GUICtrlCreateListView("",10, 170, 580, 350)
_GUICtrlListView_AddColumn($SavList,"idx",0)
_GUICtrlListView_AddColumn($SavList,"Level ID",90)
_GUICtrlListView_AddColumn($SavList,"Title",290)
_GUICtrlListView_AddColumn($SavList,"Save1",60)
_GUICtrlListView_AddColumn($SavList,"Save2",60)
_GUICtrlListView_AddColumn($SavList,"Save3",60)
GetLevels($savePath,$SavList)


GUICtrlCreateLabel ("Copy from",20,545,100)
$fromList = GUICtrlCreateCombo("",70,541,200,20)
GUICtrlCreateLabel ("to",280,545,100)
$toList = GUICtrlCreateCombo("Save slot #1",300,541,200,20)
GUICtrlSetData($toList,"Save slot #2")
GUICtrlSetData($toList,"Save slot #3")
GUICtrlSetData($toList,"Harddrive")

$copyBtn = GUICtrlCreateButton("Copy", 510, 541, 70, 20)
GUICtrlSetState($copyBtn,$GUI_DISABLE)

GUISetState(@SW_SHOW)



Dim $saveScores[3]
$lastidx = -1
$prefix = ""
While 1
	$idx = _GUICtrlListView_GetSelectedIndices($SavList)
	If $idx<>$lastidx And $idx<>"" Then
		GUICtrlSetState($copyBtn,$GUI_ENABLE)
		$lastidx = Number($idx)

		$listIdx = _GUICtrlListView_GetItemText($SavList,$lastidx,0)
		$level = _GUICtrlListView_GetItemText($SavList,$lastidx,1)
		$title = _GUICtrlListView_GetItemText($SavList,$lastidx,2)
		$saveScores[0] = _GUICtrlListView_GetItemText($SavList,$lastidx,3)
		$saveScores[1] = _GUICtrlListView_GetItemText($SavList,$lastidx,4)
		$saveScores[2] = _GUICtrlListView_GetItemText($SavList,$lastidx,5)
		DebugPrint($lastidx & ", " & $level & "," & $title & "," & $saveScores[0] & "," & $saveScores[1] & "," & $saveScores[2] & "; " & $savedLevels[$listIdx][0])

		GUICtrlSetData($fromList,"|Save slot #1","Save slot #1")
		If $saveScores[1]<>"-" Then
			GUICtrlSetData($fromList,"Save slot #2")
		EndIf
		If $saveScores[2]<>"-" Then
			GUICtrlSetData($fromList,"Save slot #3")
		EndIf

		$prefix = $level
		If $title=="Campaign" Then
			$prefix = "cmp" & $level
		EndIf

		$saveFiles = _FileListToArray(@WorkingDir,$prefix & "*.sav")
		For $i=1 to UBound($saveFiles)-1
			$file = $saveFiles[$i]
			$file = StringMid($file,StringLen($prefix)+2)
			$file = StringReplace($file,".sav","")
			GUICtrlSetData($fromList,$file)
		Next

	EndIf

	$msg = GUIGetMsg()
	Switch $msg
		Case $GUI_EVENT_CLOSE
		  ExitLoop

		Case $folderBtn
			$savePath = FileSelectFolder("Select save folder",$saveRoot,-1,$saveRoot)
			IniWrite($iniFile,"general","path",$savePath)
			GetLevels($savePath,$SavList)


		Case $backupBtn
			$backup = @WorkingDir & "\save_" & StringReplace(_NowCalcDate(),"/","") & "-" & StringReplace(_NowTime(4),":","") & ".dat"
			$saved = FileCopy($savePath & "\save.dat",$backup,1)
			If $saved==1 Then
				MsgBox(0,"INFO","Backup file has been saved to '" & $backup & "'.")
			Else
				MsgBox(0,"ERROR","Backup file could not be saved to '" & $backup & "'.")
			EndIf

		Case $restoreBtn
			$restore = FileOpenDialog("Select backup file to restore.",@WorkingDir,"Save files (save*.dat)",1)
			If $restore<>"" Then
				$restored = FileCopy($restore,$savePath & "\save.dat",1)
				If $restored==1 Then
					MsgBox(0,"INFO","Backup file '" & $restore & "' has been restored.")
				Else
					MsgBox(0,"ERROR","Backup file '" & $restore & "' could not be restored.")
				EndIf
			EndIf
			GetLevels($savePath,$SavList)

		Case $backupKeysBtn
			$saveRead = FileOpen($savePath & "\save.dat")
			$saveWrite = FileOpen(@WorkingDir & "\keys.sav",2)
			$done = False
			While 1
				$line = FileReadLine($saveRead)
				If @error Then ExitLoop
				If StringLeft($line,7)=="Hotbar." Then
					$done = True
					FileWriteLine($saveWrite,$line)
				ElseIf $done Then
					ExitLoop
				EndIf
			WEnd
			FileClose($saveWrite)
			FileClose($saveRead)
			MsgBox(0,"INFO","Key shortcuts have been updated.")

		Case $restoreKeysBtn
			FileMove($savePath & "\save.dat",$savePath & "\save.tmp",1)
			$saveRead1 = FileOpen($savePath & "\save.tmp")
			$saveRead2 = FileOpen(@WorkingDir & "\keys.sav")
			$saveWrite = FileOpen($savePath & "\save.dat",2)
			While 1
				$line = FileReadLine($saveRead1)
				If @error Then ExitLoop
				If StringLeft($line,7)=="Hotbar." Then
					$line = FileReadLine($saveRead2)
				EndIf
				FileWriteLine($saveWrite,$line)
			WEnd
			FileClose($saveWrite)
			FileClose($saveRead2)
			FileClose($saveRead1)
			FileDelete($savePath & "\save.tmp")
			MsgBox(0,"INFO","Key shortcuts have been restored")

		Case $copyBtn
			$source = GUICtrlRead($fromList)
			$target = GUICtrlRead($toList)
			;DebugPrint($source & " -> " & $target)
			If $source==$target Then ContinueCase


			$solution = ""
			$score = ""
			If StringInStr($source,"#") Then
				$fromSlot = -1
				$score = ""
				If StringInStr($source,"#") Then
					$fromSlot = Number(StringMid($source,StringInStr($source,"#")+1))
					;DebugPrint("from Slot: " & $fromSlot)
					$score = "_" & $saveScores[$fromSlot-1]
					$score = StringReplace($score,"/","-")
				EndIf
				$solution = $savedLevels[$listIdx][7+$fromSlot]
			Else
				$filename = @WorkingDir & "\" & $prefix & "_" & $source & ".sav"
				$saveHdl = FileOpen($filename)
				If $saveHdl==-1 Then
					MsgBox(0,"ERROR","Could not open '" & $filename & "'!")
					ContinueCase
				Else
					$solution = FileReadLine($saveHdl)
					FileClose($saveHdl)
					DebugPrint($solution)
				EndIf
			EndIf


			If $target=="Harddrive" Then
				$filename = StringReplace(_NowCalcDate(),"/","") & $score
				$saveHD = InputBox("Save solution","File name to save to." & @CRLF & "(A prefix containing the level name will autmoatically be added.)",$filename)
				$filename = "\" & $prefix & "_" & $saveHD & ".sav"
				DebugPrint($lastidx & ", " & $savedLevels[$listIdx][0] & "/" & $savedLevels[$listIdx][1] & ": " & $solution)
				$saveHdl = FileOpen(@WorkingDir & $filename,2)
				FileWriteLine($saveHdl,$solution)
				FileClose($saveHdl)
			Else
				$toSlot = Number(StringMid($target,StringInStr($target,"#")+1))
				$lineStart = "Solution." & $level & "." & String($toSlot-1)
				$startLen = StringLen($lineStart)
				$overwrite = False
				If $savedLevels[$listIdx][7+$toSlot]<>"" Then
					$overwrite = True
					DebugPrint("overwrite " & $lineStart)
				EndIf
				FileMove($savePath & "\save.dat",$savePath & "\save.tmp",1)
				$saveRead = FileOpen($savePath & "\save.tmp")
				$saveWrite = FileOpen($savePath & "\save.dat",2)
				$done = False
				While 1
					$line = FileReadLine($saveRead)
					If @error Then ExitLoop
					If Not $done Then
						If $overwrite Then
							If StringLeft($line,$startLen)==$lineStart Then
								$line = $lineStart & " = " & $solution
								$done = True
							EndIf
						Else
							If StringLeft($line,$startLen)>$lineStart Then
								FileWriteLine($saveWrite,$lineStart & " = " & $solution)
								$done = True
							EndIf
						EndIf
					EndIf
					FileWriteLine($saveWrite,$line)
				WEnd
				FileClose($saveWrite)
				FileClose($saveRead)
				FileDelete($savePath & "\save.tmp")
				MsgBox(0,"INFO","Save file has been updated.")
			EndIf

	EndSwitch
WEnd


