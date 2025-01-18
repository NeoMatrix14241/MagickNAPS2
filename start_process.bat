@echo off
title Tribute Kay Sir Marc (NAPS2 OCR pero Tesseract OCR engine gamit)
color 0a
cls

echo ------------------------------------------------------------------------------------------
echo SIR MARC WALA NA KAU GAGAWIN DTO AND SA MGA SCRIPT
echo JUST RUN AND FORGET SABAY UWI
echo NAG ADD AKO COLOR BLACK BACKGROUND, GREEN TEXT PARA THE MATRIX
echo ------------------------------------------------------------------------------------------
echo.
echo Instructions:
echo 1.) Ilagay ang iOCR sa input na nag generate after marun itong script (start_process.bat)
echo 2.) Press enter to start :)
echo.
echo Remarks:
echo 1.) After ma OCR laman ng "input" folder, magmove un sa "archive" folder
echo 2.) check ang output folder bka d pantay lalo by batch of 20 files lng to (limitation ng naps2 console)
echo.
echo.



:PROMPT
set /p userInput=Please type "Sir Marc Lang Malakas" to proceed: 
if /i "%userInput%"=="Sir Marc Lang Malakas" (
	cls
	powershell.exe -ExecutionPolicy RemoteSigned -File "naps2-batch.ps1"
	pause
) else (
	echo Mali ng input, umulit ka.
	goto PROMPT
)