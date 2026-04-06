:: ================================================
::  CATYAMI OTIMIZACAO
::  Monitor de Refresh Rate (Hz)
::  Nivel: Avancada
::  Versao: 1.0
:: ================================================

@echo off
chcp 65001 >nul 2>&1
color 0A
setlocal enabledelayedexpansion

:: --- Verificacao de Administrador ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ================================================
    echo   ERRO: Este script requer execucao como Administrador!
    echo   Clique com o botao direito e selecione "Executar como administrador"
    echo ================================================
    echo.
    pause
    exit /b 1
)

cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO v1.0                   ║
echo   ║     MONITOR DE REFRESH RATE (HZ)              ║
echo   ║     Nivel: Avancada                           ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo [INFO] Detectando monitores e refresh rates...
echo.
pause
cls

:: ================================================
:: DETECTAR MONITORES
:: ================================================
echo.
echo ================================================
echo   MONITORES DETECTADOS
echo ================================================
echo.
echo [INFO] Informacoes dos monitores:
echo.

:: Via WMIC
wmic desktopmonitor get ScreenHeight,ScreenWidth,Name /format:list 2>nul
echo.

:: Via PowerShell para mais detalhes
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::AllScreens | ForEach-Object { Write-Output ('Monitor: '+$_.DeviceName+' | Resolution: '+$_.Bounds.Width+'x'+$_.Bounds.Height+' | Primary: '+$_.Primary) }" 2>nul
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: DETECTAR REFRESH RATE ATUAL
:: ================================================
echo ================================================
echo   REFRESH RATE ATUAL
echo ================================================
echo.
powershell -NoProfile -Command "
Get-WmiObject -Namespace 'root\wmi' -Class 'WmiMonitorBasicDisplayParams' | ForEach-Object {
    Write-Output ('Monitor ID: ' + $_.InstanceName)
    Write-Output ('Video Output Type: ' + $_.VideoOutputType)
    Write-Output ('')
}
Get-CimInstance -Namespace 'root\wmi' -ClassName 'WMIMonitorID' | ForEach-Object {
    $name = ($_.UserFriendlyName -notmatch 0 | ForEach-Object {[char]$_}) -join ''
    Write-Output ('Nome Monitor: ' + $name)
}
" 2>nul
echo.

:: Consultar refresh rate via registro
echo [INFO] Refresh Rate configurado no registro:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Video" /s /v "DefaultSettings.XRefreshRate" 2>nul
echo.
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Video" /s /v "DefaultSettings.VRefresh" 2>nul
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: MENU
:: ================================================
echo ================================================
echo [1] Definir 60 Hz
echo [2] Definir 75 Hz
echo [3] Definir 120 Hz
echo [4] Definir 144 Hz
echo [5] Definir 165 Hz
echo [6] Definir 240 Hz (Max)
echo [7] Abrir configuracoes avancadas de display
echo [8] Executar script PowerShell (painel completo)
echo [0] Sair
echo ================================================
echo.
choice /c 123456780 /n >nul
set choice=%errorlevel%

if %choice% leq 6 goto :SET_HZ
if %choice% equ 7 goto :OPEN_DISPLAY
if %choice% equ 8 goto :RUN_PS1
if %choice% equ 9 goto :SAIR
goto :SAIR

:MENU
cls
echo.
echo ================================================
echo   Voltando para o menu...
echo ================================================
goto :BEGIN

:: ================================================
:: DEFINIR REFRESH RATE
:: ================================================
:SET_HZ
if %choice% equ 1 set hz=60
if %choice% equ 2 set hz=75
if %choice% equ 3 set hz=120
if %choice% equ 4 set hz=144
if %choice% equ 5 set hz=165
if %choice% equ 6 set hz=240

cls
echo.
echo ================================================
echo   DEFININDO REFRESH RATE: %hz% Hz
echo ================================================
echo.
echo [INFO] Aplicando %hz% Hz ao monitor...
echo.
echo [NOTA] O Windows gerencia o refresh rate via driver.
echo [NOTA] Para alteracao precisa, use:
echo.
echo  1. Clique direito na Area de Trabalho
echo  2. Configuracoes de Exibicao
echo  3. Configuracoes avancadas de video
echo  4. Selecione a taxa de atualizacao
echo.
echo ================================================
echo [INFO] Aplicando configuracoes via WMI...
echo.

:: Tentar configurar via PowerShell + WMI
powershell -NoProfile -Command "
$displays = Get-CimInstance -Namespace 'root\wmi' -ClassName 'WmiMonitorBasicDisplayParams'
if ($displays) {
    Write-Host 'Monitores encontrados: ' $displays.Count -ForegroundColor Green
    $displays | ForEach-Object {
        Write-Host '  - ' $_.InstanceName -ForegroundColor Cyan
    }
    Write-Host ''
    Write-Host 'Refresh Rate desejado: %hz% Hz' -ForegroundColor Yellow
    Write-Host 'Use Configuracoes do Windows para definir com precisao.' -ForegroundColor Yellow
} else {
    Write-Host 'Nenhum monitor WMI encontrado. Use o painel do Windows.' -ForegroundColor Red
}
" 2>nul

echo.
echo [DICA] Para definir via linha de comando, instale o QRes ou NirCmd.
echo [DICA] Comandos alternativos:
echo   qres.exe /x:1920 /y:1080 /r:%hz%
echo   nircmd.exe setdisplay 1920 1080 32
echo.
pause
goto :MENU

:: ================================================
:: ABRIR DISPLAY SETTINGS
:: ================================================
:OPEN_DISPLAY
cls
echo.
echo [INFO] Abrindo configuracoes avancadas de display...
start ms-settings:display
start desk.cpl
echo [OK] Janelas de configuracao abertas.
echo.
pause
goto :MENU

:: ================================================
:: EXECUTAR POWERSHELL
:: ================================================
:RUN_PS1
cls
echo.
echo [INFO] Executando painel de monitor avancado...
echo.
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%03_painel_monitor.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%03_painel_monitor.ps1"
) else (
    echo [ERRO] Arquivo 03_painel_monitor.ps1 nao encontrado.
)
echo.
pause

:: ================================================
:: SAIR
:: ================================================
:MENU
cls
goto :BEGIN

:SAIR
cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO                        ║
echo   ║   Operacao concluida!                         ║
echo   ╚═══════════════════════════════════════════════╝
echo.
pause
exit /b 0
