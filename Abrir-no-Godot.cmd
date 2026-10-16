@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start-godot.ps1" -Editor
if errorlevel 1 pause
