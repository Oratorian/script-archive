@echo off
setlocal enabledelayedexpansion ENABLEEXTENSIONS
title Batch Password Generator 1.0

set /a Length=15
set /a TempLength=!Length!
set Select=NULL
set Password=

:Main
cls
echo .
echo .
echo   [ Batch Password Generator ]
echo .
echo .
echo   1) Length: !Length!
echo   2) Generate New Password
echo   3) Quit
echo .
echo .
echo|set/p =!Password!|clip
echo Result: !Password!
choice /c 123456 /n /cs /t 9999 /d 6 /m "Choose an option from the list."
set Select=!errorlevel!

if %Select%==1 goto SetLength
if %Select%==2 (
	set /a TempLength=!Length!
	set Password=
	echo Generating New Password...
	goto SetPassword )
if %Select%==3 goto Quit
goto Main

:SetLength
cls
echo .
echo   Set Length:
echo .
echo   Note: Valid range is 1 - 100
set /p Length=
if !Length! LSS 1 goto SetLength
if !Length! GTR 100 goto SetLength
goto Main

:SetPassword
set /a Type=!random! %% 4
if "!Type!"=="0" (
    set /a Num=!random! %% 10
    set Password=!Password!!Num!
    goto EndSetPassword
)
if "!Type!"=="1" (
	set /a Num=!random! %% 26
    	if "!Num!"=="0" (
        	set Password=!Password!a
        	goto EndSetPassword
    	)	
	if "!Num!"=="1" (
        	set Password=!Password!b
        	goto EndSetPassword
    	)
	if "!Num!"=="2" (
        	set Password=!Password!c
        	goto EndSetPassword
    	)
	if "!Num!"=="3" (
        	set Password=!Password!d
        	goto EndSetPassword
    	)
	if "!Num!"=="4" (
        	set Password=!Password!e
        	goto EndSetPassword
    	)
	if "!Num!"=="5" (
        	set Password=!Password!f
        	goto EndSetPassword
    	)
	if "!Num!"=="6" (
        	set Password=!Password!g
        	goto EndSetPassword
    	)
	if "!Num!"=="7" (
        	set Password=!Password!h
        	goto EndSetPassword
    	)
	if "!Num!"=="8" (
        	set Password=!Password!i
        	goto EndSetPassword
    	)
	if "!Num!"=="9" (
        	set Password=!Password!j
        	goto EndSetPassword
    	)
	if "!Num!"=="10" (
        	set Password=!Password!k
        	goto EndSetPassword
    	)
	if "!Num!"=="11" (
        	set Password=!Password!l
        	goto EndSetPassword
    	)
	if "!Num!"=="12" (
        	set Password=!Password!m
        	goto EndSetPassword
    	)
	if "!Num!"=="13" (
        	set Password=!Password!n
        	goto EndSetPassword
    	)
	if "!Num!"=="14" (
        	set Password=!Password!o
        	goto EndSetPassword
    	)
	if "!Num!"=="15" (
        	set Password=!Password!p
        	goto EndSetPassword
    	)
	if "!Num!"=="16" (
        	set Password=!Password!q
        	goto EndSetPassword
    	)
	if "!Num!"=="17" (
        	set Password=!Password!r
        	goto EndSetPassword
    	)
	if "!Num!"=="18" (
        	set Password=!Password!s
        	goto EndSetPassword
    	)
	if "!Num!"=="19" (
        	set Password=!Password!t
        	goto EndSetPassword
    	)
	if "!Num!"=="20" (
        	set Password=!Password!u
        	goto EndSetPassword
    	)
	if "!Num!"=="21" (
        	set Password=!Password!v
        	goto EndSetPassword
    	)
	if "!Num!"=="22" (
        	set Password=!Password!w
        	goto EndSetPassword
    	)
	if "!Num!"=="23" (
        	set Password=!Password!x
        	goto EndSetPassword
    	)
	if "!Num!"=="24" (
        	set Password=!Password!y
        	goto EndSetPassword
    	)
	if "!Num!"=="25" (
        	set Password=!Password!z
        	goto EndSetPassword
    	)	
)

if "!Type!"=="2" (
	set /a Num=!random! %% 26
    	if "!Num!"=="0" (
        	set Password=!Password!A
        	goto EndSetPassword
    	)	
	if "!Num!"=="1" (
        	set Password=!Password!B
        	goto EndSetPassword
    	)
	if "!Num!"=="2" (
        	set Password=!Password!C
        	goto EndSetPassword
    	)
	if "!Num!"=="3" (
        	set Password=!Password!D
        	goto EndSetPassword
    	)
	if "!Num!"=="4" (
        	set Password=!Password!E
        	goto EndSetPassword
    	)
	if "!Num!"=="5" (
        	set Password=!Password!F
        	goto EndSetPassword
    	)
	if "!Num!"=="6" (
        	set Password=!Password!G
        	goto EndSetPassword
    	)
	if "!Num!"=="7" (
        	set Password=!Password!H
        	goto EndSetPassword
    	)
	if "!Num!"=="8" (
        	set Password=!Password!I
        	goto EndSetPassword
    	)
	if "!Num!"=="9" (
        	set Password=!Password!J
        	goto EndSetPassword
    	)
	if "!Num!"=="10" (
        	set Password=!Password!K
        	goto EndSetPassword
    	)
	if "!Num!"=="11" (
        	set Password=!Password!L
        	goto EndSetPassword
    	)
	if "!Num!"=="12" (
        	set Password=!Password!M
        	goto EndSetPassword
    	)
	if "!Num!"=="13" (
        	set Password=!Password!N
        	goto EndSetPassword
    	)
	if "!Num!"=="14" (
        	set Password=!Password!O
        	goto EndSetPassword
    	)
	if "!Num!"=="15" (
        	set Password=!Password!P
        	goto EndSetPassword
    	)
	if "!Num!"=="16" (
        	set Password=!Password!Q
        	goto EndSetPassword
    	)
	if "!Num!"=="17" (
        	set Password=!Password!R
        	goto EndSetPassword
    	)
	if "!Num!"=="18" (
        	set Password=!Password!S
        	goto EndSetPassword
    	)
	if "!Num!"=="19" (
        	set Password=!Password!T
        	goto EndSetPassword
    	)
	if "!Num!"=="20" (
        	set Password=!Password!U
        	goto EndSetPassword
    	)
	if "!Num!"=="21" (
        	set Password=!Password!V
        	goto EndSetPassword
    	)
	if "!Num!"=="22" (
        	set Password=!Password!W
        	goto EndSetPassword
    	)
	if "!Num!"=="23" (
        	set Password=!Password!X
        	goto EndSetPassword
    	)
	if "!Num!"=="24" (
        	set Password=!Password!Y
        	goto EndSetPassword
    	)
	if "!Num!"=="25" (
        	set Password=!Password!Z
        	goto EndSetPassword
    	)	
)

if "!Type!"=="3" (
	set /a Num=!random! %% 5
	if "!Num!"=="0" (
        	set Password=!Password!@
        	goto EndSetPassword
    	)
	if "!Num!"=="1" (
        	set Password=!Password!#
        	goto EndSetPassword
    	)
	if "!Num!"=="2" (
        	set Password=!Password!$
        	goto EndSetPassword
    	)

)

:EndSetPassword
if !TempLength! GTR 1 (
    set /a TempLength=!TempLength! - 1
    goto SetPassword
)
ECHO ^[!date! !time!] [L:!Length!] !Password!!\n!>>"PWGen_Log.ini"
goto Main


:Quit
quit
