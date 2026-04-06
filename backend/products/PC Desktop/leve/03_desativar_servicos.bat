@echo off
chcp 65001 >nul
color 0A
title Catyami - Desativar Servicos

echo ========================================================
echo          CATYAMI - DESATIVAR SERVICOS DESNECESSARIOS
echo ========================================================
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%~f0\"\"&pause\"'"
    exit /b
)

echo Desativando servicos de telemetria e desnecessarios...
echo.

sc config DiagTrack start=disabled >nul 2>&1
echo [OK] DiagTrack desativado (telemetria Windows)

sc config dmwappushservice start=disabled >nul 2>&1
echo [OK] dmwappushservice desativado (telemetria)

sc config WerSvc start=disabled >nul 2>&1
echo [OK] WerSvc desativado (relatorio de erros)

sc config RetailDemo start=disabled >nul 2>&1
echo [OK] RetailDemo desativado (demo de loja)

sc config MapsBroker start=demand >nul 2>&1
echo [OK] MapsBroker configurado para manual

sc config OneSyncSvc start=disabled >nul 2>&1
echo [OK] OneSyncSvc desativado (sincronizacao)

sc config PcaSvc start=disabled >nul 2>&1
echo [OK] PcaSvc desativado (assistencia de compatibilidade)

sc config TroubleshootingSvc start=disabled >nul 2>&1
echo [OK] TroubleshootingSvc desativado (solucao de problemas)

echo.
echo ========================================================
echo     SERVICOS DESATIVADOS COM SEGURANCA
echo     Para reverter: sc config NOME_SERVICO start=auto
echo ========================================================
echo.
pause
