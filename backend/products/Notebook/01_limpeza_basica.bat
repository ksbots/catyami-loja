@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Limpeza Basica

echo ========================================================
echo        CATYAMI NOTEBOOK - LIMPEZA BASICA
echo ========================================================
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%~f0\"\"&pause\"'"
    exit /b
)

echo [1/5] Limpando %%TEMP%%...
del /q /f /s %TEMP%\* >nul 2>&1
echo     [OK] Temporarios removidos.

echo [2/5] Limpando Prefetch...
del /q /f /s C:\Windows\Prefetch\* >nul 2>&1
echo     [OK] Cache Prefetch limpo.

echo [3/5] Limpando Windows Temp...
del /q /f /s C:\Windows\Temp\* >nul 2>&1
echo     [OK] Temp do Windows limpo.

echo [4/5] Limpando cache navegadores...
del /q /f /s "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
echo     [OK] Cache dos navegadores limpo.

echo [5/5] Limpando lixeira...
PowerShell -NoProfile -Command "Clear-RecycleBin -Confirm:$false -Force" >nul 2>&1
echo     [OK] Lixeira esvaziada.

echo.
echo [REDE] Otimizando latencia...
ipconfig /flushdns >nul 2>&1
echo     [OK] DNS limpo.
netsh int ip reset >nul 2>&1
echo     [OK] TCP/IP reset.

echo.
echo ========================================================
echo         LIMPEZA DO NOTEBOOK CONCLUIDA!
echo ========================================================
echo.
pause
