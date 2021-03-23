#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Persistent
#SingleInstance, force
#Include includes\WinRun.ahk
#Include includes\WebRequests.ahk
#Include includes\JSON.ahk

APP_NAME        := "Soundy"
VERSION         := "0.0.6"
TAG_LINE        := "Distributed Soundboard - Join the Party"
SOUNDS          := A_ScriptDir . "\Sounds\"
BASEDOMAIN      := "https://sb.dns.wtf/"
CHECKINURL      := BASEDOMAIN . "api/latest.json?id"
SOUNDURL        := BASEDOMAIN . "api/latest.json?song"
CURRENTIDURL    := BASEDOMAIN . "api/latest.json?start"
UPDATEURL       := BASEDOMAIN . "api/update.json"
SWIMMERS        := BASEDOMAIN . "api/swimmers.json"
LAST_ID         := readConfig("lastid", 0)
SAFE_MODE       := readConfig("safemode", 0)
MUTE_MODE       := readConfig("mutemode", 0)
POOL_ID         := readConfig("poolid", 1)
debug           := readConfig("debugmode", 0)
NOTIFICATIONS   := readConfig("notifications", 1)
CHECKFORUPDATES := readConfig("updates", 1)
Logfile         := A_ScriptDir . "\runtime.log"
IterationLimit   = 120
CURRENT_ID       = 0
RUNCOUNT         = 0
HOSTNAME        := A_ComputerName

Menu, SettingsMenu, Add, SFW Only, ToggleSFW
Menu, SettingsMenu, Add, Mute, ToggleMute
Menu, SettingsMenu, Add, Debug, ToggleDebug
Menu, SettingsMenu, Add, Update Pool, UpdatePool
Menu, SettingsMenu, Add, Check For Updates, ToggleUpdates
Menu, SettingsMenu, Add,
Menu, SettingsMenu, Add, View Logs, Logs
Menu, SettingsMenu, Add, Clear Logs,ClearLogs

Menu, tray, NoStandard
Menu, tray, add, %APP_NAME% %VERSION%, Reload
Menu, tray, add, About,About
Menu, tray, add,
Menu, tray, Add, Settings, :SettingsMenu
Menu, tray, Add, Update Now, Update
Menu, Tray, Disable, Update Now
Menu, tray, add,
Menu, tray, add, Quit, Exit

Menu, tray, tip, %APP_NAME% %VERSION% - %LAST_ID%

; TODO: Create About Gui
about_message := APP_NAME . " " . VERSION . "`n`r`n`rThis tool allows you to be part of the party`n`r`n`rMore information about this script can be found at: `n`r`n`r    https://github.com/smugzombie `n`r`n`ror by contacting us at: scripts@digdns.com."
Gui 2: Add, GroupBox, x6 y6 w340 h180 , Copyright (C) 2021 Ron Egli
Gui 2: Add, Edit, x16 y25 w320 h150 disabled, %about_message%

if (SAFE_MODE == 1){
	Menu, SettingsMenu, Check , SFW Only
}
if (MUTE_MODE == 1){
	Menu, SettingsMenu, Check, Mute
}
if (debug == 1){
	Menu, SettingsMenu, Check, Debug
}
if (CHECKFORUPDATES == 1){
	Menu, SettingsMenu, Check, Check For Updates
}
;msgbox % "Last ID" . LAST_ID

If ( !A_IsCompiled ) {
	; If not compiled, use the local icon
	Menu, Tray, Icon, ricardo.ico
}

checkForUpdates()
getCurrentID()
; Lets kick things off
DebugLogThis("Started")
DebugLogThis("Current ID set to: " . LAST_ID)
DebugLogThis("Current Pool set to: " . POOL_ID)
DebugLogThis("Current MUTE Setting: " . MUTE_MODE)
DebugLogThis("Current SAFE Setting: " . SAFE_MODE)
DebugLogThis("Current UPDATE Settings: " . CHECKFORUPDATES)
DebugLogThis("Current Identifier: " . HOSTNAME)
doStuff()

return

update:
Run, https://github.com/SmugZombie/DistributedSoundBoard
return

checkForUpdates(){
	global
	if (CHECKFORUPDATES != 1){
		return
	}

	command := A_ScriptDir . "\includes\curl " . UPDATEURL . " -k -s"
	latestVersion := CMDRun(command)

	Latest := VersionCompare(VERSION, latestVersion)

	if (Latest == 2){
		Notify("Update Available - v" . latestVersion)
		Menu, Tray, Enable, Update Now
	}

	; Check for updates
}

EmptyMem(PID="Soundy"){
    pid:=(pid="Soundy") ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}

doStuff(){
    global
    if(RUNCOUNT > IterationLimit){
    	DebugLogThis("Reloading at " . IterationLimit . " iterations.")
    	reload
    }
    else{
    	DebugLogThis("Iteration: " + RUNCOUNT)
		if (IntervalOf5(RUNCOUNT)){
			fetchSwimmers()
		}
    }
    getSong()
}

fetchSwimmers(){
	global
	
	TEMPSWIMMERS := SWIMMERS . "?pool=" . POOL_ID
	;DebugLogThis(TEMPSWIMMERS)
	command := A_ScriptDir . "\includes\curl " . TEMPSWIMMERS . " -k -s"
    CURRENT_SWIMMERS := CMDRun(command)

	DebugLogThis(CURRENT_SWIMMERS)
	CURRENT_SWIMMERS = 
}

getCurrentID(){
	global
	TEMPCURRENTIDURL := CURRENTIDURL . "&last_id=" . LAST_ID . "&pool=" . POOL_ID . "&identifier=" . HOSTNAME . "&safemode=" . SAFE_MODE
	;DebugLogThis(TEMPCURRENTIDURL)
    command := A_ScriptDir . "\includes\curl " . TEMPCURRENTIDURL . " -k -s"
    LAST_ID := CMDRun(command)

    StringReplace,LAST_ID,LAST_ID,`r`n,,A
    StringReplace,LAST_ID,LAST_ID,`n,,A
    StringReplace,LAST_ID,LAST_ID,`r,,A

    writeConfig("lastid", LAST_ID)

    return LAST_ID
}

getSong(){
    global
    
    if(MUTE_MODE == 1){
        Sleep 1000
        doStuff()
    }
    else{

        TEMPCHECKINURL := CHECKINURL . "&last_id=" . LAST_ID . "&pool=" . POOL_ID . "&safemode=" . SAFE_MODE . "&identifier=" . HOSTNAME
        ;DebugLogThis(TEMPCHECKINURL)
        command := A_ScriptDir . "\includes\curl " . TEMPCHECKINURL . " -k -s"
        lastSong := CMDRun(command)

        StringReplace,lastSong,lastSong,`r`n,,A
        StringReplace,lastSong,lastSong,`n,,A
        StringReplace,lastSong,lastSong,`r,,A

        if(lastSong > LAST_ID){
            getSongName(lastSong)
        }

        RUNCOUNT := RUNCOUNT + 1
        Sleep 1000
    	EmptyMem()
        doStuff()
    }
}

getSongName(id){
    global

    if(CURRENT_ID == id){
        ; Do Nothing
        return
    }
    else{
        CURRENT_ID := id
        ;DebugLogThis("Updating Current ID to: " . CURRENT_ID)
        LogThis("New ID Found")

        TEMPSOUNDURL := SOUNDURL . "&pool=" . POOL_ID . "&last_id=" . LAST_ID . "&safemode=" . SAFE_MODE
        ;DebugLogThis(TEMPSOUNDURL)
        command := A_ScriptDir . "\includes\curl " . TEMPSOUNDURL . " -k -s"
        songName := CMDRun(command)

        StringReplace,songName,songName,`r`n,,A
        StringReplace,songName,songName,`n,,A
        StringReplace,songName,songName,`r,,A

        IfInString, songName, NSFW
    	{
    		if( SAFE_MODE == 1 ){
    			LogThis("Safemode Saves the Day!")
    			return
    		}
    	}

        ;msgbox % songName . "..."

        songExists(songName)
    }

    
}

songExists(name){
    global
    file := SOUNDS . name
    if FileExist(file){
    	LogThis(name . " already exists on disk")
        playSong(name)
    }
    else{
    	LogThis(name . " not found, fetching from web")
        downloadSong(name)
    }
}

downloadSong(name){
    global
    ;msgbox % name
    fileURL := BASEDOMAIN . "sounds/" . name
    filePath := SOUNDS . name
    ;msgbox % filePath


    if not FileExist(SOUNDS){
    	FileCreateDir, %SOUNDS%
    }

    UrlDownloadToFile, %fileURL%, %filePath%

    ;command := A_ScriptDir . "\includes\curl " . fileURL . " --output " . filePath

    ;msgbox % fileURL

	;songName := CMDRun(command)

    playSong(name)
}

playSong(name){
    global
    if(CURRENT_ID == LAST_ID){

    }
    else{
    	LogThis("Now Playing: " . name)
        filePath := SOUNDS . name
        LAST_ID := CURRENT_ID
        writeConfig("lastid", LAST_ID)
        Menu, tray, tip, %APP_NAME% %VERSION% - %LAST_ID%
        ;SoundPlay, %SOUNDS%%name%
        ;command := A_ScriptDir . "\includes\player.exe filename=" . filePath
        ;songName := CMDRun(command)
        Run, % A_ScriptDir . "\includes\player.exe filename=" . filePath
    }
    
}

readConfig(name, default=""){
	global
	RegRead, RegKeyValue, HKEY_CURRENT_USER\Software\%APP_NAME%, %name%

	;msgbox % RegKeyValue

	if(RegKeyValue == ""){
		writeConfig(name, default)
		return default
	}

	return RegKeyValue
}

writeConfig(name, value){
	global
	RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\%APP_NAME%, %name%, %value%
	LogThis("Writing Registry: " . name . " Value: " . value)
	return
}

ToggleSFW:
	if(SAFE_MODE = 1)
	{
		SAFE_MODE = 0
		Menu,SettingsMenu,UnCheck, SFW Only
	}
	Else
	{
		SAFE_MODE = 1
		Menu,SettingsMenu,Check, SFW Only
	}
	DebugLogThis("Toggling SAFE Mode to: " . SAFE_MODE)

	writeConfig("safemode", SAFE_MODE)
return

ToggleMute:
	if(MUTE_MODE = 1)
	{
		MUTE_MODE = 0
		Menu,SettingsMenu,UnCheck, Mute
	}
	Else
	{
		MUTE_MODE = 1
		Menu,SettingsMenu,Check, Mute
	}
	DebugLogThis("Toggling MUTE Mode to: " . MUTE_MODE)

	writeConfig("mutemode", MUTE_MODE)
return

ToggleDebug:
	if(debug = 1)
	{
		debug = 0
		Menu,SettingsMenu,UnCheck, Debug
	}
	Else
	{
		debug = 1
		Menu,SettingsMenu,Check, Debug
	}
	DebugLogThis("Toggling debug Mode to: " . debug)

	writeConfig("debugmode", debug)
	reload
return

ToggleUpdates:
	if(CHECKFORUPDATES = 1)
	{
		CHECKFORUPDATES = 0
		Menu, SettingsMenu, UnCheck, Check For Updates
	}
	Else
	{
		CHECKFORUPDATES = 1
		Menu, SettingsMenu, Check, Check For Updates
	}
	writeConfig("checkforupdates", CHECKFORUPDATES)
	;checkStartup()
return

Reload:
reload

Exit:
DebugLogThis("Quitting by User Choice")
ExitApp

UpdatePool:
InputBox, UserInput, Pool ID, Please enter your Pool Id (%POOL_ID%)., , 640, 480
if ErrorLevel{
	; Do Nothing
}
else{
    writeConfig("poolid", UserInput)
}
return

LogThis(string){
	global
	StringReplace,string,string,`r`n,,A
	FormatTime, Time,, MM/dd/yy hh:mm:ss tt
	logline = %Time% - %APP_NAME%  %VERSION% - %string%
	FileAppend, %logline%`n, %Logfile%
}

DebugLogThis(string){
	global
	if(debug == 1){
		LogThis("Debug: " string)
	}
}

VersionCompare(version1, version2)
{
	StringSplit, verA, version1, .
	StringSplit, verB, version2, .
	Loop, % (verA0> verB0 ? verA0 : verB0)
	{
		if (verA0 < A_Index)
			verA%A_Index% := "0"
		if (verB0 < A_Index)
			verB%A_Index% := "0"
		if (verA%A_Index% > verB%A_Index%)
			return 1
		if (verB%A_Index% > verA%A_Index%)
			return 2
	}
	return 0
}

Notify(message){
	global
	if(NOTIFICATIONS != 1)
	{ 
		return 
	}
	goSub RemoveTrayTip
	TrayTip, %APP_NAME%, %message%
	SetTimer, RemoveTrayTip, 2500
	return
}

About:
Gui 2: -Resize -MinimizeBox -MaximizeBox
Gui 2: Show, h190 w350, %APP_NAME% %version% - About
return

RemoveTrayTip:
SetTimer, RemoveTrayTip, Off
TrayTip
return

Logs:
openInNotepad(Logfile)
return

ClearLogs:
MsgBox, 4, , Are you sure you want to delete the logs? 
IfMsgBox, Yes
	FileDelete, %LogFile%
return

openInNotepad(file_path){
	global
	IfNotExist, %file_path%
	{
		msgbox,,%APP_NAME%, File Not Found
		return
	}
	Run Notepad.exe %file_path%
}

IntervalOf5(Number)
{
	Switch Mod(Number,5)
	{
		Case 0:
			return true
			; Send, x
		Case 1:
			return false
			; Send, y
	}
}
