@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Limpar Background

echo ========================================================
echo        CATYAMI NB - LIMPAR PROCESSOS BACKGROUND
echo ========================================================
echo.

echo Finalizando processos em segundo plano...
taskkill /f /im OneDrive.exe >nul 2>&1
echo [OK] OneDrive fechado
taskkill /f /im Spotify.exe >nul 2>&1
echo [OK] Spotify fechado
taskkill /f /im Discord.exe >nul 2>&1
echo [OK] Discord fechado
taskkill /f /im Steam.exe >nul 2>&1
echo [OK] Steam fechado
taskkill /f /im Origin.exe >nul 2>&1
echo [OK] Origin fechado
taskkill /f /im GameBar.exe >nul 2>&1
echo [OK] GameBar fechado
taskkill /f /im Skype.exe >nul 2>&1
echo [OK] Skype fechado

echo.
echo [REDE] Otimizando latencia apos limpeza...
ipconfig /flushdns >nul 2>&1
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
echo     [OK] Rede otimizada

echo.
echo Processos atuais em execucao:
tasklist | findstr /v "svchost" | findstr /v "Search" | findstr /v "RuntimeBroker"
echo.
echo ========================================================
echo    PROCESSOS BACKGROUND FINALIZADOS!
echo    Nota: Processos essenciais nao foram afetados.
echo ========================================================
echo.
pause
