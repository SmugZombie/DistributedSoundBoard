; Author: Ron Egli - ron.egli@tvrms.com
; Project: BreachRadar - http://www.breachradar.com
; Purpose: This file makes use of cURL via AHK
; ScriptName: UrlGet.exe
; Version: 0.9

;[HEAD]
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

;[BODY]
UrlGet(url){
	command = \curl.exe -s -k %url%
	response := CMDRun(A_ScriptDir command)
	Return, response
}

UrlPost(url, arguments){
	command = \curl.exe --data "%arguments%" -s -k %url%
	response := CMDRun(A_ScriptDir command)
	Return, response
}

UrlPostJSON(url, json){
	command = \curl.exe -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112 Safari/534.30" -H "Content-Type: application/json" --data %json% -s -k %url%
	response := CMDRun(A_ScriptDir command)
	Return, response
}

;[EOF]