@echo off
chcp 65001 >nul
color 0A
title Catyami - Ajuste de RAM

echo ========================================================
echo               CATYAMI - AJUSTE DE RAM
echo ========================================================
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%~f0\"\"&pause\"'"
    exit /b
)

echo [1/4] Configurando pagina de memoria (Auto Managed)...
wmic pagefileset /set AutomaticManaged=TRUE >nul 2>&1
echo     [OK] Pagina de memoria configurada para automatica.

echo [2/4] Limpando memoria stand-by...
PowerShell -Command "& {[System.GC]::Collect()}" >nul 2>&1
echo     [OK] Coleta de lixo executada.

echo [3/4] Configurando SysMain (Superfetch)...
sc config SysMain start=auto >nul 2>&1
sc start SysMain >nul 2>&1
echo     [OK] SysMain (Superfetch) habilitado e iniciado.

echo [4/4] Exibindo uso atual de RAM...
for /f "tokens=2 delims==" %%a in ('wmic OS get FreePhysicalMemory /value ^| find "="') do (
    for /f "tokens=2 delims==" %%b in ('wmic OS get TotalVisibleMemorySize /value ^| find "="') do (
        set /a free=%%a/1024
        set /a total=%%b/1024
        set /a used=total-free
        echo     RAM Livre: !free!MB / Total: !total!MB / Usada: !used!MB
    )
)

echo.
echo ========================================================
echo           AJUSTE DE RAM CONCLUIDO!
echo ========================================================
echo.
pause
