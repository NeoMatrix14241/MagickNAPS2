@echo off
powershell -ExecutionPolicy Bypass -Command & '%~dp0unblocker.ps1'
powershell.exe -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File "core\processor_gui.ps1"
