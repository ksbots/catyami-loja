@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Servicos

echo ========================================================
echo        CATYAMI NB - DESATIVAR SERVICOS PESADOS
echo ========================================================
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%~f0\"\"&pause\"'"
    exit /b
)

sc config DiagTrack start=disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
echo [OK] DiagTrack desativado (telemetria)

sc config SysMain start=disabled >nul 2>&1
sc stop SysMain >nul 2>&1
echo [OK] SysMain desativado (reduz uso de disco)

sc config WerSvc start=disabled >nul 2>&1
echo [OK] WerSvc desativado (relatorio de erros)

sc config RetailDemo start=disabled >nul 2>&1
echo [OK] RetailDemo desativado

echo.
echo [REDE] Otimizando latencia...
ipconfig /flushdns >nul 2>&1
netsh int ip reset >nul 2>&1
echo     [OK] Rede otimizada

echo.
echo ========================================================
echo         SERVICOS OTIMIZADOS NO NOTEBOOK!
echo ========================================================
echo.
pause
