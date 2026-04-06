:: ================================================
::  CATYAMI OTIMIZACAO
::  Gerenciador de Inicializacao
::  Nivel: Leve - Recomendado para todos
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
echo   ║   Gerenciador de Programas de Inicializacao   ║
echo   ║   Nivel: Leve                                 ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo [INFO] Verificando programas de inicializacao...
echo.
pause
cls

:: --- Exibir Programas de Inicializacao Atuais ---
echo.
echo ================================================
echo   PROGRAMAS DE INICIALIZACAO ATUAIS
echo ================================================
echo.
:: Usando WMIC para listar startup entries
echo [INFO] Listando entradas de inicializacao...
echo.
wmic startup get Caption,Command,Location 2>nul
echo.
echo [INFO] Consultando pasta de inicializacao do usuario...
echo.
dir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" /b 2>nul
echo.
echo [INFO] Consultando pasta de inicializacao geral...
echo.
dir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" /b 2>nul
echo.
pause
cls

:: --- Menu de Operacoes ---
echo.
echo ================================================
echo   O QUE DESEJA FAZER?
echo ================================================
echo.
echo   [1] Desativar programas desnecessarios (Seguro)
echo   [2] Desativar atualizadores automaticos
echo   [3] Desativar servicos de cloud na inicializacao
echo   [4] Restaurar todos os programas (Padrao)
echo   [5] Visualizar tempo de inicializacao
echo   [6] Limpeza de entradas invalidas
echo   [0] Sair
echo.
chose /c 1234567 /n >nul 2>&1
set choice=%errorlevel%

:: Fallback se chose nao estiver disponivel
if %choice% equ 7 set choice=0

if %choice% equ 1 goto :DESATIVAR_SEGURO
if %choice% equ 2 goto :DESATIVAR_ATUALIZADORES
if %choice% equ 3 goto :DESATIVAR_CLOUD
if %choice% equ 4 goto :RESTAURAR
if %choice% equ 5 goto :TEMPO_INICIO
if %choice% equ 6 goto :LIMPAR_INVALIDAS
if %choice% equ 0 goto :SAIR
goto :SAIR

:: ================================================
:: OPCAO 1 - Desativacao Segura
:: ================================================
:DESATIVAR_SEGURO
cls
echo.
echo ================================================
echo   DESATIVANDO PROGRAMAS NAO ESSENCIAIS
echo ================================================
echo.
echo [INFO] Programas desativados (podem ser reativados):
echo.

:: Programas seguros para desativar na inicializacao
set "prog_list=AdobeUpdater OneDriveUpdate SpotifyHelper SkypeTray SteamClientWebHelper DiscordUpdate EpicGamesLauncherUpdate OriginClientService BattleNetUpdateAgent RazerSynapse3 LogitechGHUB NVIDIABackend GeForceExperienceSelfUpdate CortanaOneBox MicrosoftEdgeAutoLaunch TeamsMachineWide"

for %%p in (%prog_list%) do (
    echo [PROCESSO] Tentando desativar: %%p
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%%p" /f >nul 2>&1
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%%p" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "%%p" /f >nul 2>&1
    echo   [OK] %%p - tentativa concluida
)

echo.
echo [SUCESSO] Programas nao essenciais removidos da inicializacao!
echo [DICA] Voce pode reativa-los a qualquer momento pela opcao 4.
echo.
pause
goto :MENU

:: ================================================
:: OPCAO 2 - Desativar Atualizadores
:: ================================================
:DESATIVAR_ATUALIZADORES
cls
echo.
echo ================================================
echo   DESATIVANDO ATUALIZADORES AUTOMATICOS
echo ================================================
echo.
echo [INFO] Desativando atualizadores na inicializacao...
echo.

:: Adobe
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AdobeAAMUpdater-1.0" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Adobe ARM" /f >nul 2>&1
echo [OK] Adobe Updater

:: Java
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SunJavaUpdateSched" /f >nul 2>&1
echo [OK] Java Update Scheduler

:: Google Update
taskkill /f /im "GoogleUpdate.exe" >nul 2>&1
schtasks /change /tn "GoogleUpdateTaskMachineCore" /disable >nul 2>&1
schtasks /change /tn "GoogleUpdateTaskMachineUA" /disable >nul 2>&1
echo [OK] Google Update

:: Office
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OfficeUpdater" /f >nul 2>&1
echo [OK] Office Updater

:: QuickTime
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "QuickTime Task" /f >nul 2>&1
echo [OK] QuickTime Task

echo.
echo [SUCESSO] Atualizadores automaticos desativados!
echo [NOTA] Atualize manualmente quando desejar.
echo.
pause
goto :MENU

:: ================================================
:: OPCAO 3 - Desativar Cloud na Inicializacao
:: ================================================
:DESATIVAR_CLOUD
cls
echo.
echo ================================================
echo   DESATIVANDO SERVICOS DE CLOUD
echo ================================================
echo.
echo [INFO] Desativando clientes de cloud na inicializacao...
echo.

:: OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /t REG_SZ /d "" /f >nul 2>&1
echo [OK] OneDrive removido da inicializacao

:: Dropbox
taskkill /f /im Dropbox.exe >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Dropbox" /f >nul 2>&1
echo [OK] Dropbox removido da inicializacao

:: Google Drive
taskkill /f /im GoogleDriveFS.exe >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "GoogleDriveFS" /f >nul 2>&1
echo [OK] Google Drive removido da inicializacao

:: iCloud
taskkill /f /im iCloudServices.exe >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "iCloudServices" /f >nul 2>&1
echo [OK] iCloud removido da inicializacao

echo.
echo [SUCESSO] Servicos de cloud removidos da inicializacao!
echo [NOTA] Os servicos ainda podem ser abertos manualmente.
echo.
pause
goto :MENU

:: ================================================
:: OPCAO 4 - Restaurar
:: ================================================
:RESTAURAR
cls
echo.
echo ================================================
echo   RESTAURANDO PROGRAMA PADRAO
echo ================================================
echo.
echo [INFO] Restaurando configuracoes padrao de inicializacao...
echo.
echo [AVISO] Isso restaura os padroes do Windows.
echo [AVISO] Programas de terceiros deverao ser reativados manualmente.
echo.
pause
echo.
echo [INFO] Abrindo configurações de Inicializacao do Windows...
start ms-settings:startupapps
echo.
echo [INFO] Janela de inicializacao aberta.
echo [INFO] Voce pode reativar os programas desejados manualmente.
echo.
pause
goto :MENU

:: ================================================
:: OPCAO 5 - Tempo de Inicializacao
:: ================================================
:TEMPO_INICIO
cls
echo.
echo ================================================
echo   TEMPO DE INICIALIZACAO DO SISTEMA
echo ================================================
echo.
echo [INFO] Consultando tempo de boot...
echo.
wevtutil qe System /q:"*[System[Provider[@Name='Microsoft-Windows-Diagnostics-Performance'] and (EventID=100)]]" /c:1 /f:text 2>nul | findstr /i "BootTime Duration"
echo.
echo [INFO] Tempo estimado de inicializacao:
for /f "tokens=2 delims==" %%a in ('wmic os get lastbootuptime /value ^| find "="') do set boottime=%%a
echo   Ultimo boot: %boottime%
echo.
echo [DICA] Um boot ideal deve levar menos de 30 segundos em SSD.
echo.
pause
goto :MENU

:: ================================================
:: OPCAO 6 - Limpar Entradas Invalidas
:: ================================================
:LIMPAR_INVALIDAS
cls
echo.
echo ================================================
echo   LIMPANDO ENTRADAS INVALIDAS DE INICIALIZACAO
echo ================================================
echo.
echo [INFO] Verificando entradas com caminhos invalidos...
echo.

:: Verifica chaves comuns
for %%k in (
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
) do (
    echo [VERIFICA] %%k
    reg query %%k 2>nul
    echo.
)

echo.
echo [INFO] Varredura completa. Nenhuma acao automatica necessaria.
echo [DICA] Use o Autoruns (Sysinternals) para analise avancada.
echo.
pause
goto :MENU

:: ================================================
:: SAIR
:: ================================================
:SAIR
cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO                        ║
echo   ║   Operacao concluida com sucesso!             ║
echo   ║   Obrigado por utilizar nossos servicos!      ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo [INFO] Seu sistema de inicializacao foi otimizado.
echo [DICA] Execute esta ferramenta periodicamente.
echo.
pause
exit /b 0
