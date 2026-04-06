@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Limpar Background

echo ========================================================
echo        CATYAMI NB - LIMPAR PROCESSOS BACKGROUND
echo ========================================================
echo.

echo Finalizando processos em segundo plano...
taskkill /f /im OneDrive.exe >nul 2>&1 && echo [OK] OneDrive
taskkill /f /im Spotify.exe >nul 2>&1 && echo [OK] Spotify
taskkill /f /im Discord.exe >nul 2>&1 && echo [OK] Discord
taskkill /f /im Steam.exe >nul 2>&1 && echo [OK] Steam
taskkill /f /im Origin.exe >nul 2>&1 && echo [OK] Origin
taskkill /f /im GameBar.exe >nul 2>&1 && echo [OK] GameBar
taskkill /f /im Skype.exe >nul 2>&1 && echo [OK] Skype

echo.
echo [REDE] Otimizando latencia...
ipconfig /flushdns >nul 2>&1
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
echo     [OK] Rede otimizada

echo.
echo ========================================================
echo    PROCESSOS BACKGROUND FINALIZADOS!
echo    Processos essenciais nao foram afetados.
echo ========================================================
echo.
pause
