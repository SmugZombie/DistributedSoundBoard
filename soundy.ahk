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
VERSION    := "0.0.1"
TAG_LINE   := "Distributed Soundboard"
SOUNDS     := A_ScriptDir . "\Sounds\"
CHECKINURL := "https://sb.dns.wtf/api/latest.json?id"
SOUNDURL   := "https://sb.dns.wtf/api/latest.json?song"
LAST_ID    := readConfig("lastid", 0)
SAFE_MODE  := readConfig("safemode", 1)
MUTE_MODE  := readConfig("mutemode", 0)
POOL_ID    := readConfig("poolid", 1)
CURRENT_ID = 0

Menu, SettingsMenu, Add, SFW Only, ToggleSFW
Menu, SettingsMenu, Add, Mute, ToggleMute

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
;msgbox % "Last ID" . LAST_ID

If ( !A_IsCompiled ) {
	; If not compiled, use the local icon
	Menu, Tray, Icon, ricardo.ico
}

; Lets kick things off
doStuff()

return

doStuff(){
    global
    getSong()
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

        Sleep 1000
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
        playSong(name)
    }
    else{
        downloadSong(name)
    }
}

downloadSong(name){
    global
    ;msgbox % name
    fileURL := "https://sb.dns.wtf/sounds/" . name
    filePath := SOUNDS . name
    ;msgbox % filePath
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
	writeConfig("mutemode", MUTE_MODE)
return

Reload:
reload

Exit:
ExitApp