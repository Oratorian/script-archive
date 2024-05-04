@echo off
:START
CLS
echo Activation Options
set /p answer=Please type [1] for Microsoft Windows, [2] for Microsoft Office or [Q] to quit: 
   if /i "%answer:~,1%" EQU "1" GOTO WINACT
   if /i "%answer:~,1%" EQU "2" GOTO OFFICECHECK
   if /i "%answer:~,1%" EQU "Q" GOTO QUIT
GOTO START

:OFFICECHECK
CLS
IF EXIST "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" (
GOTO OFFICEACT
) ELSE ( echo Office is not installed on this machine 
pause
GOTO START )

:OFFICEACT
echo.
echo We will prepare your Office install for activation, please stand by
echo.
echo.
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /ckms-domain
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /skms-domain:amhosting.de
CLS
echo Please note, this tool only activates Office 2016/2019, so please choose
set /p office=Which office do you have [1] Office 2016, [2] Office 2019 or [3] Back to the beginning: 
   if /i "%office:~,1%" EQU "1" GOTO OFF16
   if /i "%office:~,1%" EQU "2" GOTO OFF19
   if /i "%office:~,1%" EQU "3" GOTO START
GOTO OFFICEACT

:OFF19
CLS
echo We are now trying to install the Office 2019 LicenseKEYs
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:9BGNQ-K37YR-RQHF2-38RQ3-7VCBB
echo Key was installed, starting activation process
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /act
pause
GOTO OFFICEACT

:OFF16
CLS
echo We are now trying to install the Office 2016 LicenseKEYs
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:YG9NW-3K39V-2T3HJ-93F3Q-G83KT
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:PD3PC-RHNGV-FXJ29-8JK7D-RJRJK
echo Key was installed, starting activation process
cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /act
pause
GOTO OFFICEACT

:WINACT
SET "OS="
FOR /F "skip=1 tokens=*" %%a IN ('WMIC OS GET CAPTION') DO IF NOT DEFINED OS SET OS=%%a
SET OS=%OS: =%
IF "%OS%"=="MicrosoftWindows10Pro" GOTO 10PRO
IF "%OS%"=="MicrosoftWindows10Home" GOTO 10HOME
IF "%OS%"=="MicrosoftWindows10Enterprise" GOTO 10ENT
IF "%OS%"=="MicrosoftWindows10ProforWorkstations" GOTO 10PROWORK

:10PRO
echo Windows 10 Pro Edition installiert. Windows Pro GVLKKEY wird installiert
SET KEY=W269N-WFGWX-YVC9B-4J6C9-T83GX
SET OOS="Windows 10 PRO"
GOTO AKT

:10HOME
echo Windows 10 Home Edition installiert. Windows Home KEY wird installiert.
SET KEY=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
SET OOS="Windows 10 Home"
GOTO AKT

:10ENT
echo Windows 10 Enterprise Edition installiert. Windows Enterporise KEY wird installiert.
SET KEY=NPPR9-FWDCX-D2C8J-H872K-2YT43
SET OOS="Windows 10 Enterprise"
GOTO AKT

:10PROWORK
echo Windows 10 Enterprise for Workstations Edition installiert. Windows Enterporise KEY wird installiert.
SET KEY=NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J
SET OOS="Windows 10 Enterprise for Workstations"
GOTO AKT


:AKT
echo Loesche den alten Aktivierungsserver
cscript C:\Windows\System32\slmgr.vbs /ckms>/NULL
echo Loesche die alte Aktivierungsdomain
cscript C:\Windows\System32\slmgr.vbs /ckms-domain>/NULL
echo Setze neuen Aktivierungsserver
cscript C:\Windows\System32\slmgr.vbs /skms-domain amhosting.de>/NULL
echo Installiere neuen CD-KEY
FOR /F "tokens=*" %%a IN ('cscript C:\Windows\System32\slmgr.vbs /ipk %KEY% ^| findstr /i "Fehler erfolgreich"') DO IF NOT DEFINED ANSW SET ANSW=%%a
echo %ANSW%
SET "ANSW="
GOTO AKTEND

:AKTEND
FOR /F "tokens=*" %%a IN ('cscript C:\Windows\System32\slmgr.vbs /ato ^| findstr /i "Fehler erfolgreich"') DO IF NOT DEFINED ANSW SET ANSW=%%a
echo %ANSW%
pause
GOTO START

:QUIT
CLS
echo Thanks for using the automated activaton tools
pause
exit
