@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Modo Viagem

echo ========================================================
echo        CATYAMI NB - MODO VIAGEM / ULTRA LEVE
echo        Para notebooks com poucos recursos
echo ========================================================
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%~f0\"\"&pause\"'"
    exit /b
)

echo [1/6] Ativando plano Power Saver...
powercfg -setactive a1841308-3541-4fab-bc81-f71556f20b4a >nul 2>&1
echo     [OK] Plano economia ativado.

echo [2/6] Fechando processos nao essenciais...
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im Dropbox.exe >nul 2>&1
taskkill /f /im GoogleDriveFS.exe >nul 2>&1
taskkill /f /im Discord.exe >nul 2>&1
taskkill /f /im Slack.exe >nul 2>&1
taskkill /f /im Teams.exe >nul 2>&1
taskkill /f /im Spotify.exe >nul 2>&1
taskkill /f /im Steam.exe >nul 2>&1
taskkill /f /im Origin.exe >nul 2>&1
taskkill /f /im EpicGamesLauncher.exe >nul 2>&1
taskkill /f /im Skype.exe >nul 2>&1
taskkill /f /im GameBar.exe >nul 2>&1
echo     [OK] Processos finalizados.

echo [3/6] Desligando telemetria...
sc config DiagTrack start=disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
echo     [OK] Telemetria desativada.

echo [4/6] Limpando cache...
ipconfig /flushdns >nul 2>&1
del /q /f /s %TEMP%\* >nul 2>&1
echo     [OK] Cache limpo.

echo [5/6] Otimizando rede para menor ping...
netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
echo     [OK] Rede otimizada.

echo [6/6] Configurando DNS Cloudflare...
netsh interface ip set dns name="Wi-Fi" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Wi-Fi" address=8.8.8.8 index=2 >nul 2>&1
echo     [OK] DNS: 1.1.1.1 + 8.8.8.8

echo.
echo ========================================================
echo           MODO VIAGEM ATIVADO!
echo ========================================================
echo   Seu notebook esta no modo mais leve possivel.
echo.
echo   PARA REVERTER:
echo     powercfg -setactive (seu plano normal)
echo     netsh interface set interface "Wi-Fi" enabled
echo ========================================================
echo.
pause
