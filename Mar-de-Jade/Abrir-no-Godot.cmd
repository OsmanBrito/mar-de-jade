@echo off
setlocal
set "JADE_GODOT=C:\Users\gamer\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe"
if exist "%JADE_GODOT%" (
  start "Godot - Mar de Jade" "%JADE_GODOT%" --editor --path "%~dp0."
  exit /b 0
)
echo Abre project.godot com o Godot 4.5.1.
pause
