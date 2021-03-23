#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#SingleInstance, force
#Include includes\WinRun.ahk
#Include includes\WebRequests.ahk
#Include includes\JSON.ahk
#Persistent

APP_NAME   := "Soundy"
VERSION    := "0.0.3"
TAG_LINE   := "Distributed Soundboard"
SOUNDS     := A_ScriptDir . "\Sounds\"
CHECKINURL := "https://sb.dns.wtf/api/latest.json?id"
SOUNDURL   := "https://sb.dns.wtf/api/latest.json?song"
CURRENTIDURL   := "https://sb.dns.wtf/api/latest.json?start"
LAST_ID    := readConfig("lastid", 0)
SAFE_MODE  := readConfig("safemode", 1)
MUTE_MODE  := readConfig("mutemode", 0)
POOL_ID    := readConfig("poolid", 1)
debug      := readConfig("debug", 0)
Logfile    := A_ScriptDir . "\runtime.log"
IterationLimit = 120
CURRENT_ID = 0
RUNCOUNT = 0

Menu, SettingsMenu, Add, SFW Only, ToggleSFW
Menu, SettingsMenu, Add, Mute, ToggleMute
Menu, SettingsMenu, Add, Debug, ToggleDebug
Menu, SettingsMenu, Add, Update Pool, UpdatePool

Menu, tray, NoStandard
Menu, tray, add, %APP_NAME% %VERSION%, Reload
;Menu, tray, add, About,About
Menu, tray, add,
Menu, tray, Add, Settings, :SettingsMenu
;Menu, tray, Add, Update Now, Update
;Menu, Tray, Disable, Update Now
Menu, tray, add,
Menu, tray, add, Quit, Exit

Menu, tray, tip, %APP_NAME% %VERSION% - %LAST_ID%

if (SAFE_MODE == 1){
	Menu, SettingsMenu, Check , SFW Only
}
if (MUTE_MODE == 1){
	Menu, SettingsMenu, Check, Mute
}
if (debug == 1){
	Menu, SettingsMenu, Check, Debug
}
;msgbox % "Last ID" . LAST_ID

If ( !A_IsCompiled ) {
	; If not compiled, use the local icon
	Menu, Tray, Icon, ricardo.ico
}

getCurrentID()
; Lets kick things off
DebugLogThis("Started")
DebugLogThis("Current ID set to: " . LAST_ID)
DebugLogThis("Current Pool set to: " . POOL_ID)
DebugLogThis("Current MUTE Setting: " . MUTE_MODE)
DebugLogThis("Current SAFE Setting: " . SAFE_MODE)
doStuff()

return

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
    }
    getSong()
}

getCurrentID(){
	global
	CURRENTIDURL := CURRENTIDURL . "&last_id=" . LAST_ID . "&pool=" . POOL_ID
    command := A_ScriptDir . "\includes\curl " . CURRENTIDURL . " -k -s"
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
        CHECKINURL := CHECKINURL . "&last_id=" . LAST_ID . "&pool=" . POOL_ID
        command := A_ScriptDir . "\includes\curl " . CHECKINURL . " -k -s"
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
        DebugLogThis("Updating Current ID to: " . CURRENT_ID)
        LogThis("New ID Found")

        SOUNDURL := SOUNDURL . "&pool=" . POOL_ID
        command := A_ScriptDir . "\includes\curl " . SOUNDURL . " -k -s"
        songName := CMDRun(command)

        StringReplace,songName,songName,`r`n,,A
        StringReplace,songName,songName,`n,,A
        StringReplace,songName,songName,`r,,A

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
    fileURL := "https://sb.dns.wtf/sounds/" . name
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

	writeConfig("debug", debug)
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
	logline = %Time% - %APP_NAME% - %string%
	FileAppend, %logline%`n, %Logfile%
}

DebugLogThis(string){
	global
	debug := readConfig("debug", 1)
	if(debug == 1){
		LogThis("Debug: " string)
	}
}