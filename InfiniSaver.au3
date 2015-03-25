#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=infinisaver.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <Date.au3>
#Include <Misc.au3>
#Include <Array.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <GuiStatusBar.au3>
#include <WindowsConstants.au3>

$saveRoot = @UserProfileDir & "\My Documents\My Games\Infinifactory\"
$savePath = $saveRoot

$iniFile = @WorkingDir & "\InfiniSaver.ini"
$customPath = ""
							; 0       1		 2			  3			   4			 5				 6				  7				  8			     9				10				11			 12			  13
Global $savedLevels[1][14] ; [levelID,title, slot1:cycles,slot2:cycles,slot3:cycles, slot1:footprint,slot2:footprint,slot3:footprint, slot1:solution,slot2:solution,slot3:solution, slot1:blocks,slot2:blocks,slot3:blocks]
$campaign = 0
$campaignInfo = False
Dim $workshopSolutions[1]

Global $efficiency = "b/(c*.35+f)"
If FileExists($iniFile) Then
	$customPath = IniRead($iniFile,"general","path","")
	If $customPath<>"" Then
		$savePath = $customPath
		$saveRoot = StringLeft($savePath,StringInStr($savePath,"\",0,-1)-1)
	EndIf
	$efficiency = IniRead($iniFile,"general","efficiency",$efficiency)

	$campaign = IniReadSection($iniFile,"campaign")
	If @error==0 Then $campaignInfo = True
EndIf

If FileExists($saveRoot) And $customPath=="" Then
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
	Next
	$savePath = $saveRoot & $newestFolder
EndIf



;==================================================================

Func DebugPrint($msg)
    ConsoleWrite($msg & @CRLF)
    DllCall("kernel32.dll", "none", "OutputDebugString", "str", "[K] " & $msg)
EndFunc

Func GetLevelIdx($level)
	$levelIdx = -1
	For $i=0 to UBound($savedLevels,1)-1
		If $savedLevels[$i][0]==$level Then
			$levelIdx = $i
			ExitLoop
		EndIf
	Next
	;DebugPrint($level & ", " & $levelIdx)
	Return $levelIdx
EndFunc

Func GetTitle ($path,$level,$isCampaign)
	$title = ""
	If $isCampaign Then
		If $campaignInfo Then
			$worldId = StringLeft($level,1)
			$worldIdx = _ArraySearch($campaign, $worldId & "-0")
			If $worldIdx<>-1 Then
				$worldName = $campaign[$worldIdx][1]
				$levelIdx = _ArraySearch($campaign,$level,0,0,2)
				If $levelIdx<>-1 Then
					$title = $worldName & ": " & $campaign[$levelIdx][1]
				EndIf
			EndIf
		EndIf
	Else
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
	EndIf
	Return $title
EndFunc

Func ShowScore($level,$list)
	For $i=0 To UBound($savedLevels,1)-2
		If $savedLevels[$i][0]==$level Then
			$title = $savedLevels[$i][1]
			If $title=="" Then ExitLoop
			;DebugPrint($level & ", " & $title)

			$idx = _GUICtrlListView_AddItem($list,$i,0)
			_GUICtrlListView_AddSubItem($list, $idx, $level,1)
			_GUICtrlListView_AddSubItem($list, $idx, $title,2)
			$info = $level & ", " & $title
			For $savidx=0 To 2
				;DebugPrint('  ' & $savidx & ": " & $savedLevels[$i][$savidx+8])
				$save = "-"
				If $savedLevels[$i][$savidx+2]<>"" Then
					$cycles = $savedLevels[$i][$savidx+2]
					$foot = $savedLevels[$i][$savidx+5]
					$blocks = $savedLevels[$i][$savidx+11]
					$save = $cycles & "/" & $foot
					$effVal = CalcEfficiency($cycles,$foot,$blocks)
					If $info<>"" Then
						DebugPrint($info)
						$info = ""
					EndIf
					DebugPrint('  ' & $cycles & "/" & $foot & "/" & $blocks & "=" & Round($effVal,2))
				Else
					If $savedLevels[$i][$savidx+8]<>"" Then
						$save = "WiP"
					EndIf
				EndIf
				_GUICtrlListView_AddSubItem($list, $idx, $save,$savidx+3)
			Next
		EndIf
	Next
EndFunc

Func GetBlockCount($cntstr)
	$hi2 = (Asc(StringMid($cntstr,3,1))-65) * 256
	$hi = (Asc(StringLeft($cntstr,1))-65) * 16
	$lo = StringInStr("AEIMQUYcgkosw048",StringMid($cntstr,2,1))-1
	$blocks = $hi2 + $hi + $lo
	;DebugPrint($cntstr & ", " & $hi & "+" & $lo & "+" & $hi2 & ": " & $blocks)
	Return $blocks
EndFunc

Func GetLevels($path,$list)
	_GUICtrlListView_DeleteAllItems($list)

	$savHdl = FileOpen($path & "\save.dat")

	$level = ""
	$title = ""
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

			$levelIdx = GetLevelIdx($level)
			If $levelIdx==-1 Then
				$savedLevels[UBound($savedLevels,1)-1][0] = $level
				$savedLevels[UBound($savedLevels,1)-1][$idxoff+$slot] = $score
				ReDim $savedLevels[UBound($savedLevels,1)+1][14]
				;DebugPrint("new: " & $level & ", " & $slot & ", " & $type & ", " & $score  & ", " & $idxoff+$slot)
			Else
				$savedLevels[$levelIdx][$idxoff+$slot] = $score
				;DebugPrint("old: " & $level & ", " & $slot & ", " & $type & ", " & $score  & ", " & $idxoff+$slot)
			EndIf
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
					$blocks = GetBlockCount(StringMid($solution,6,3))
					;DebugPrint($level & "." & $slot & ": " & $blocks)
					$title = GetTitle($path,$level,$start<>"w")
					;DebugPrint($level & ", " & $title)

					If $title<>"" Then
						If $start=="w" Then
							If _ArraySearch($workshopSolutions,$level)==-1 Then
								$workshopSolutions[UBound($workshopSolutions)-1] = $level
								ReDim $workshopSolutions[UBound($workshopSolutions)+1]
							EndIf
						EndIf

						$levelIdx = GetLevelIdx($level)
						If $levelIdx==-1 Then
							$idx = UBound($savedLevels,1)
							$savedLevels[$idx-1][0] = $level
							$savedLevels[$idx-1][1] = $title
							$savedLevels[$idx-1][8+$slot] = $solution
							$savedLevels[$idx-1][11+$slot] = $blocks
							ReDim $savedLevels[$idx+1][14]
						Else
							$savedLevels[$levelIdx][1] = $title
							$savedLevels[$levelIdx][8+$slot] = $solution
							$savedLevels[$levelIdx][11+$slot] = $blocks
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	WEnd
	FileClose($savHdl)

	; show the campaign results
	For $i=1 To UBound($campaign,1)-1
		$level = $campaign[$i][0]
		$levelIdx = GetLevelIdx($level)
		If $levelIdx<>-1 Then
			ShowScore($level,$list)
		EndIf
	Next
	For $i=1 To UBound($workshopSolutions,1)-2
		ShowScore($workshopSolutions[$i],$list)
	Next
EndFunc

Func CalcEfficiency($c,$f,$b)
	$eff = StringReplace($efficiency,"b",$b)
	$eff = StringReplace($eff,"c",$c)
	$eff = StringReplace($eff,"f",$f)
	$effVal = Execute($eff)
	Return Round($effVal,2)
EndFunc

Global $iItem_old = -1, $iSubItem_old = -1
Func UpdToolTip($mylist)
    Local $aHit = _GUICtrlListView_SubItemHitTest($mylist)

    If $aHit[0] < 0 Or $aHit[1] < 0 Or $aHit[1]<3 Then
        If $iItem_old = -1 Or $iSubItem_old = -1 Then Return
        $iItem_old = -1
        $iSubItem_old = -1
        Return ToolTip('')
    EndIf

    If $aHit[0] = $iItem_old And $aHit[1] = $iSubItem_old Then Return

	$listIdx = _GUICtrlListView_GetItemText($mylist,$aHit[0],0)

    $info = "Row " & $aHit[0] & " Col " & $aHit[1] & ", "
    $info = ""
	$cycles = $savedLevels[$listIdx][$aHit[1]-1]
	$foot = $savedLevels[$listIdx][$aHit[1]+2]
	$blocks = $savedLevels[$listIdx][$aHit[1]+8]
	If $blocks<>0 Then
		$info = "Blocks: " & $blocks
		If $cycles*$foot<>0 Then
			$effVal = CalcEfficiency($cycles,$foot,$blocks)
			$info = "Cycles: " & $cycles & ", Footprint: " & $foot & ", Blocks: " & $blocks & @CRLF & "Efficiency: " & Round($effVal,2)
		EndIf
	EndIf
	ToolTip($info)
    $iItem_old = $aHit[0]
    $iSubItem_old  = $aHit[1]
EndFunc


;==================================================================

$guiWidth = 600
$guiHeight = 590

$hGUI = GUICreate("Infinifactory Game Save Manager",$guiWidth, $guiHeight)

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
_GUICtrlListView_AddColumn($SavList,"Level ID",80)
_GUICtrlListView_AddColumn($SavList,"Title",298)
_GUICtrlListView_AddColumn($SavList,"Save1",60)
_GUICtrlListView_AddColumn($SavList,"Save2",60)
_GUICtrlListView_AddColumn($SavList,"Save3",60)
GetLevels($savePath,$SavList)
$listHdl = GUICtrlGetHandle(-1)


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
		;DebugPrint($lastidx & ", " & $level & "," & $title & "," & $saveScores[0] & "," & $saveScores[1] & "," & $saveScores[2] & "; " & $savedLevels[$listIdx][0])

		GUICtrlSetData($fromList,"|Save slot #1","Save slot #1")
		If $saveScores[1]<>"-" Then
			GUICtrlSetData($fromList,"Save slot #2")
		EndIf
		If $saveScores[2]<>"-" Then
			GUICtrlSetData($fromList,"Save slot #3")
		EndIf

		$prefix = $level
		If StringInStr($level,"-") Then
			$prefix = "cmp" & $level
		EndIf

		$saveFiles = _FileListToArray(@WorkingDir,$prefix & "*.sav")
		For $i=1 to UBound($saveFiles)-1
			$file = $saveFiles[$i]
			$file = StringMid($file,StringLen($prefix)+2)
			$file = StringReplace($file,".sav","")
			If $file<>"" Then
				GUICtrlSetData($fromList,$file)
			EndIf
		Next

	EndIf

	$msg = GUIGetMsg()
	Switch $msg
		Case $GUI_EVENT_CLOSE
		  ExitLoop

		Case $GUI_EVENT_MOUSEMOVE
			UpdToolTip($listHdl)

		Case $folderBtn
			$savePath = FileSelectFolder("Select save folder",$saveRoot,-1,$saveRoot)
			If $savePath<>"" Then
				IniWrite($iniFile,"general","path",$savePath)
				GetLevels($savePath,$SavList)
			EndIf

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
					While 1
						$line2 = FileReadLine($saveRead2)
						If @error Then ExitLoop
						FileWriteLine($saveWrite,$line2)
					WEnd
				Else
					FileWriteLine($saveWrite,$line)
				EndIf
			WEnd
			FileClose($saveWrite)
			FileClose($saveRead2)
			FileClose($saveRead1)
			FileDelete($savePath & "\save.tmp")
			MsgBox(0,"INFO","Key shortcuts have been restored")

		Case $copyBtn
			$source = GUICtrlRead($fromList)
			$target = GUICtrlRead($toList)
			If $source==$target Then ContinueCase

			$solution = ""
			$score = ""
			If StringInStr($source,"#") Then
				$fromSlot = -1
				$score = ""
				If StringInStr($source,"#") Then
					$fromSlot = Number(StringMid($source,StringInStr($source,"#")+1))
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
				EndIf
			EndIf

			If $target=="Harddrive" Then
				$filename = StringReplace(_NowCalcDate(),"/","") & $score
				$saveHD = InputBox("Save solution","File name to save to." & @CRLF & "(A prefix containing the level name will autmoatically be added.)",$filename)
				If $saveHD<>"" Then
					$filename = "\" & $prefix & "_" & $saveHD & ".sav"
					;DebugPrint($lastidx & ", " & $savedLevels[$listIdx][0] & "/" & $savedLevels[$listIdx][1] & ": " & $solution)
					$saveHdl = FileOpen(@WorkingDir & $filename,2)
					FileWriteLine($saveHdl,$solution)
					FileClose($saveHdl)
				EndIf
			Else
				$toSlot = Number(StringMid($target,StringInStr($target,"#")+1))
				$lineStart = "Solution." & $level & "." & String($toSlot-1)
				$startLen = StringLen($lineStart)
				FileMove($savePath & "\save.dat",$savePath & "\save.tmp",1)
				$saveRead = FileOpen($savePath & "\save.tmp")
				$saveWrite = FileOpen($savePath & "\save.dat",2)
				$done = False
				While 1
					$line = FileReadLine($saveRead)
					If @error Then ExitLoop
					If Not $done Then
						If StringLeft($line,$startLen)==$lineStart Then
							$line = $lineStart & " = " & $solution
							$done = True
						ElseIf StringLeft($line,$startLen)>$lineStart Then
							FileWriteLine($saveWrite,$lineStart & " = " & $solution)
							$done = True
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


