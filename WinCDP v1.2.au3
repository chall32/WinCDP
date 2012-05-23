#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=3
#AutoIt3Wrapper_Res_Description=Cisco Discovery Protocol Analyser
#AutoIt3Wrapper_Res_Fileversion=0.1.2.0
#AutoIt3Wrapper_Res_LegalCopyright=Chris Hall 2010-2012
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_Field=ProductName|WinCDP
#AutoIt3Wrapper_Res_Field=ProductVersion|1.2
#AutoIt3Wrapper_Res_Field=OriginalFileName|WinCDPv1.2.exe
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;===================================================================================================================================================================
; WinCDP - Cisco Discovery for Windows - Chris Hall 2010-2012
; History:
;  Alpha 1 - 01/06/2010
;   Initial release
;
; Alpha 2 - 02/06/2010
;   Fixed non detection & cancel mid discovery hang
;   Always return switch names in uppercase
;   Added countdown timer
;   Tweak startup splash dialogue
;
; Beta 1 - 07/07/2010
;	Fixed UAC, Added require admin rights loop
;
; Beta 2 - 05/04/2011
;	Show VLAN ID
;	Added Save Data Button
;	Better tcpdump.exe handling
;
; Release 1.0 - 06/04/2011
;	Show Switch port Duplex
;	Show VTP Management Doamin
;	Hide task tray icon
;	Remove "Cisco" text from switch model output
;
; Release 1.1 - 13/07/2011
; 	Move "NO CDP DATA FOUND ... !" message to status box
;	Result data width increased
;
; Release 1.2 - 04/05/2012
; 	Added NIC hardware lookup, display & save
;	Better UAC icon handling
;	Zero input error handling via popup
;	Remove free text entry in Network Connection selection drop down
;	Declare file descriptors
;
; TO DO:
;	Enumerate all button?
;===================================================================================================================================================================
$VER = "1.2"

#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <File.au3>
#Include <String.au3>
#include <GuiButton.au3>
#include <ComboConstants.au3>
$WinCDPVer = "WinCDP - v"& $VER &" - Chris Hall - 2010-" & @YEAR

if IsAdmin() = 0 then
	MsgBox(16,"Exiting","This program requires Local Admistrator rights")
	Exit
	EndIf
FileInstall("tcpdump.exe", @TempDir & '\', 1)
GUISetIcon("cisco.ico")

$log = FileOpen(@TempDir & "\CDP.txt", 2)
$wbemFlagReturnImmediately = 0x10
$wbemFlagForwardOnly = 0x20
$colItems = ""
$strComputer = "localhost"
$Output=""
$Nic_Friend =""
$Hardware=""
$IData=""
SplashTextOn("Please Wait","Enumerating Network Cards via WMI...", 300, 50)
$objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
If IsObj($colItems) then
   For $objItem In $colItems
			FileWriteLine($log, "[" & $objItem.NetConnectionID & "]")
			FileWriteLine($log, "ProductName=" & $objItem.ProductName)
			$value = $objItem.NetConnectionID
			If StringLen($value) > 1 Then $Output = $Output & $value & "|"
			$colItems2 = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
			For $objItem2 In $colItems2
				If $objItem.Index = $objItem2.Index Then
					FileWriteLine($log, "SettingID=" & $objItem2.SettingID)
				EndIf
			Next
	Next
Else
   Msgbox(0,"WMI Output","No WMI Objects Found for class: " & "Win32_NetworkAdapterConfiguration" )
Endif
SplashOff()
GUICreate("Cisco Discovery for Windows", 550, 400, (@DesktopWidth - 550) / 2, (@DesktopHeight - 400) / 2, $WS_OVERLAPPEDWINDOW + $WS_VISIBLE + $WS_CLIPSIBLINGS)
GUICtrlCreateGroup("Selection ", 15, 10, 520, 110)
GUICtrlCreateLabel("Network Connection:", 30, 35, 100, 20)
$Nic_Friendly = GUICtrlCreateCombo("",145,33,350,20, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, $Output)
GUICtrlCreateLabel("Network Card:", 30, 62, 100, 20)
$Get = GUICtrlCreateButton("Get CDP Data", 120, 85, 100)
$Save = GUICtrlCreateButton("Save CDP Data", 260, 85, 100)
$Cancel = GUICtrlCreateButton("Cancel", 400, 85, 100)
If RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA") > 0 Then
    GUICtrlSetImage($Get, "imageres.dll", -2, 0)
	 _GUICtrlButton_SetShield($Get)
EndIf
GUICtrlCreateGroup("Results ", 15, 130, 520, 160)
GUICtrlCreateLabel("Switch Name:", 30, 160, 70, 20)
GUICtrlCreateLabel("Port Identifier:", 30, 190, 70, 20)
GUICtrlCreateLabel("VLAN Identifier:", 30, 220, 75, 20)
GUICtrlCreateLabel("Switch IP Address:", 30, 250, 90, 20)
GUICtrlCreateLabel("Switch Model:", 280, 160, 70, 20)
GUICtrlCreateLabel("Port Duplex:", 280, 190, 70, 20)
GUICtrlCreateLabel("VTP Mgmt Domain:", 280, 220, 95, 20)
GUICtrlCreateGroup("Status ", 15, 300, 520, 65)
GUICtrlCreateLabel($WinCDPVer, 350, 375, 200, 20)

GUISetState()
	While 1
		Switch GUIGetMsg()

		Case $Nic_Friendly
			$Nic_Friend = GUICtrlRead ($Nic_Friendly)
			$IData = IniReadSection(@TempDir & "\CDP.txt", $Nic_Friend)
			$Hardware = $IData[1][1]
			GUICtrlCreateLabel($Hardware, 145, 62, 350, 20)
			ClearResults()
		 Case $Get
			If GUICtrlRead($Nic_Friendly) = "" Then
			   MsgBox(64,"Invalid Selection", "Please select a network card using the dropdown")
			   ContinueLoop
			EndIf
			GetCDP($Nic_Friendly)
		Case $GUI_EVENT_CLOSE
			OnExit()
			ExitLoop
		Case $Cancel
			OnExit()
			ExitLoop
		Case $Save
			SaveData()
		Case Else
				;;;
		EndSwitch
	WEnd
Exit
	Func GetCDP($Nic_Friendly)
		$SaveFile = FileOpen(@TempDir & "\SaveCDP.txt", 2)
		GUICtrlSetState($Get, $GUI_DISABLE)
		GUICtrlSetState($Save, $GUI_DISABLE)
		ClearResults()
		FileWriteLine($SaveFile, $Nic_Friend & " (" & $Hardware & ") is connected to:")
		FileWriteLine($SaveFile, "------------------------------------------------------")
		$ID = $IData[2][1]
		$TCPDmpPID = Run(@ComSpec & " /c " & @TempDir & '\tcpdump.exe -i \Device\' & $ID & ' -nn -v -s 1500 -c 1 ether[20:2] == 0x2000 >%temp%\CDP_OUT.txt', "", @SW_HIDE)
		$Secs = 1
		$Status1 = GUICtrlCreateLabel("Running ... May take up to 60 seconds between CDP announcements ...", 120, 317, 350, 20 )
		$iBegin = TimerInit()
		Do
			$msg = GUIGetMsg()
			If $msg = $Cancel Then
				ProcessClose("tcpdump.exe")
				ExitLoop
			EndIf
			If Ceiling(TimerDiff($iBegin)) = ($Secs * 1000) or Ceiling(TimerDiff($iBegin)) > ($Secs * 1000) Then
				GUICtrlCreateLabel(Round($Secs,0) & " Seconds Elapsed", 240, 337, 100, 20 )
				$Secs = $Secs + 1
			EndIf
			$TCPDmpPID = ProcessExists($TCPDmpPID)
		Until $TCPDmpPID = "0" Or TimerDiff($iBegin) > 60000
		GUICtrlDelete($Status1)
		GUICtrlCreateLabel("", 240, 337, 100, 20 )
		GUICtrlCreateLabel("", 210, 317, 200, 20)
$file = FileOpen(@TempDir & "\CDP_OUT.txt")
$end = _FileCountLines(@TempDir & "\CDP_OUT.txt")
If $end > 0 Then
$line = 0
Do
	If StringInStr(FileReadLine($file, $line), "Device-ID (0x01)") Then
		$SwitchName = StringSplit(FileReadLine($file, $line), "'")
		$SwitchName = StringUpper($SwitchName[2])
		GUICtrlCreateLabel($SwitchName, 140, 160, 120, 20)
		FileWriteLine($SaveFile, "Switch Name:	" & $SwitchName)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Port-ID (0x03)") Then
		$SwitchPort = StringSplit(FileReadLine($file, $line), "'")
		GUICtrlCreateLabel($SwitchPort[2], 140, 190, 120, 20)
		FileWriteLine($SaveFile, "Switch Port:	" & $SwitchPort[2])
	EndIf
	If StringInStr(FileReadLine($file, $line), "VLAN ID (0x0a)") Then
		$VLAN = StringSplit(FileReadLine($file, $line), ":")
		$VLAN = StringStripWS($VLAN[3],8)
		GUICtrlCreateLabel($VLAN, 140, 220, 120, 20)
		FileWriteLine($SaveFile, "VLAN ID:	" & $VLAN)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Address (0x02)") Then
		$SwitchIP = StringSplit(FileReadLine($file, $line), ")")
		$SwitchIP = StringStripWS($SwitchIP[3],8)
		GUICtrlCreateLabel($SwitchIP, 140, 250, 120, 20)
		FileWriteLine($SaveFile, "Switch IP:	" & $SwitchIP)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Platform (0x06)") Then
		$SwitchModel = StringSplit(FileReadLine($file, $line), "'")
		$SwitchModel = StringTrimLeft (StringUpper($SwitchModel[2]), 6)
		GUICtrlCreateLabel($SwitchModel, 390, 160, 120, 20)
		FileWriteLine($SaveFile, "Switch Model:	" & $SwitchModel)
	EndIf
	If StringInStr(FileReadLine($file, $line), "Duplex (0x0b)") Then
		$Duplex = StringSplit(FileReadLine($file, $line), ":")
		$Duplex = StringLower(StringStripWS($Duplex[3],8))
		$Duplex = _StringProper($Duplex)
		GUICtrlCreateLabel($Duplex, 390, 190, 120, 20)
		FileWriteLine($SaveFile, "Switch Duplex:	" & $Duplex)
	EndIf
	If StringInStr(FileReadLine($file, $line), "VTP Management Domain (0x09)") Then
		$VTP = StringSplit(FileReadLine($file, $line), "'")
		GUICtrlCreateLabel($VTP[2], 390, 220, 120, 20)
		FileWriteLine($SaveFile, "VTP Mgmt:	" & $VTP[2])
	EndIf

	$line = $line + 1
Until $line = $end
Else
	If ProcessExists("tcpdump.exe") Then ProcessClose("tcpdump.exe")
	GUICtrlCreateLabel("NO CDP DATA FOUND ... !", 210, 317, 150, 20)
	FileClose($SaveFile)
	FileDelete(@TempDir & "\SaveCDP.txt")
EndIf
	FileClose($SaveFile)
	FileClose($file)
	FileDelete(@TempDir & "\CDP_OUT.txt")
	GUICtrlSetState($Get, $GUI_ENABLE)
	GUICtrlSetState($Save, $GUI_ENABLE)
	EndFunc

	Func ClearResults()
		GUICtrlCreateLabel("", 140, 160, 120, 20)
		GUICtrlCreateLabel("", 140, 190, 120, 20)
		GUICtrlCreateLabel("", 140, 220, 120, 20)
		GUICtrlCreateLabel("", 140, 250, 120, 20)
		GUICtrlCreateLabel("", 390, 160, 120, 20)
		GUICtrlCreateLabel("", 390, 190, 120, 20)
		GUICtrlCreateLabel("", 390, 220, 120, 20)
	EndFunc

	Func SaveData()
		If FileExists(@TempDir & "\SaveCDP.txt") = 0 Then Return
		$UserSave = FileSaveDialog("Save CDP Data to","::{20D04FE0-3AEA-1069-A2D8-08002B30309D}","Text Documents (*.txt)", 16)
		If $UserSave = "" Then Return
		If StringInStr($UserSave, ".txt") = 0 Then $UserSave = $UserSave & ".txt"
		FileCopy(@TempDir & "\SaveCDP.txt",$UserSave)
	EndFunc

	Func OnExit()
		If ProcessExists("tcpdump.exe") Then ProcessClose("tcpdump.exe")
		FileClose($log)
		FileDelete(@TempDir & "\CDP.txt")
		FileDelete(@TempDir & "\tcpdump.exe")
		FileDelete(@TempDir & "\SaveCDP.txt")
	EndFunc