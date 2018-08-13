::author MrLeopard

@echo off 
mode con: cols=80 lines=35
adb start-server
setlocal enabledelayedexpansion

:pathChose
cls
if exist %temp%\screencfg.ini (goto check_path)
if NOT exist %temp%\screencfg.ini (
echo ===================ENG=======================
echo select the path to save files:
echo Input 1.Current directory,screenrecord folder.
echo Input 2.Desktop,screenrecord folder.
echo User-defined.input a exist directory.cannot have Chinese and space.
echo ==============================================
echo ===================CHN========================
echo 选择文件的保存路径:
echo 输入 1.将保存在脚本所在路径的screenrecord目录下.
echo 输入 2.将保存在桌面的screenrecord目录中.
echo 自定义.输入已存在的目录，不支持中文和空格.
echo ==============================================
)
set /P path_input=:
if not defined path_input (goto pathChose)
if %path_input%==1 (echo 1 > %temp%\screencfg.ini & goto pathChose)
if %path_input%==2 (echo 2 > %temp%\screencfg.ini & goto pathChose)
if not exist %path_input% echo %path_input% not exist,please input a correct director.&timeout /t 3 >nul & goto pathChose
echo %path_input%> %temp%\screencfg.ini
goto pathChose

:check_path
for /f %%i in (%temp%\screencfg.ini) do set filepath=%%i
if "%filepath%"=="" (del %temp%\screencfg.ini &goto pathChose)
if %filepath%==1 (goto check_current_screenrecord)
if %filepath%==2 (goto check_desktop_screenrecord)
if NOT exist %filepath% md %filepath%
if NOT exist %filepath% echo can not creat %filepath% ,please run me again.&^
del %temp%\screencfg.ini &timeout /t 3 >nul &goto :EOF
goto list_device

:check_current_screenrecord
set filepath=!%~dp0!\screenrecord
if not exist %filepath% md %filepath%
goto list_device

:check_desktop_screenrecord
set filepath=%USERPROFILE%\desktop\screenrecord
if not exist %filepath% md %filepath%
goto list_device


:list_device
cd %filepath%
title Select Device
cls
for /f %%i in ('adb devices ^|find /C "device"') do set /A devices=(%%i-1)
if %devices% GEQ 1 (echo %devices% device^(s^) connected
) else (
echo no device found & timeout /T 3 >nul & goto :EOF
)
echo following device(s) found:
echo ================================
set /A no=1
for /f "skip=1 tokens=1,4 delims= " %%i in ('adb devices -l') do (
echo !no!: %%j    %%i
set deivce!no!=%%i
set model!no!=%%j
set /A no=!no!+1
)

echo ================================

rem "return" SERIAL
rem usage: adb -s %SERIAL% shell xxx

if !no! EQU 2 (set model=!model1! & set SERIAL=!deivce1! & goto title)

set /a input_max=!no!-1
echo input device no, "x" to exit.（default chose is 1）
set input=1
set /P input=
if %input%==x (goto :EOF)
if %input%==X (goto :EOF)

if %input% LSS 1 (
echo must bewtten 1 and !input_max! & timeout /T 2 >nul & goto list_device
)
if %input% GEQ !no! (
echo must bewtten 1 and !input_max! & timeout /T 2 >nul & goto list_device
)

set SERIAL_ord=deivce%input%
set model_ord=model%input%
set SERIAL=!%SERIAL_ord%!
set model=!%model_ord%!

:title
title %model:~6%---%SERIAL%
pushd %filepath%

set slt=1

:main
cls
color 0F

set str=%time:~0,2%
if %str% LEQ 9 (set str=0%str: =%)
set fn=%date:~5,2%%date:~8,2%-%str%%time:~3,2%%time:~6,2%

echo chose a function,now default value is %slt%
echo ================================
echo 1:  screencap
echo 2:  screenrecord
echo d:  select device
echo r:  reset file save path
echo x:  exit
echo ================================
if %slt%==1 (echo Enter to continue)
if %slt%==2 (echo Enter to continue)
if %slt%==d (goto list_device)
if %slt%==D (goto list_device)
if %slt%==r (del %temp%\screencfg.ini &goto pathChose)
if %slt%==R (del %temp%\screencfg.ini &goto pathChose)
if %slt%==x (goto :EOF)
if %slt%==X (goto :EOF)
set /p slt=
if %slt%==0 (cls & goto main)
if %slt%==1 goto screencap
if %slt%==2 (goto screenrecord) else (cls & goto main)

:screencap
echo %cd%\%model:~6,-1%-%fn%.png
adb -s %SERIAL% shell screencap /data/local/tmp/1.png ^&
adb -s %SERIAL% pull /data/local/tmp/1.png %model:~6,-1%-%fn%.png ^&
adb -s %SERIAL% shell rm /data/local/tmp/1.png
goto main

:screenrecord
color 0c
echo %cd%\%model:~6,-1%-%fn%.mp4
echo Recording, max 180s, press Ctrl+C to break.
adb -s %SERIAL% shell screenrecord /data/local/tmp/1.mp4 &^
timeout /t 2 >nul &^
adb -s %SERIAL% pull /data/local/tmp/1.mp4 %model:~6,-1%-%fn%.mp4 &^
adb -s %SERIAL% shell rm /data/local/tmp/1.mp4
goto main
