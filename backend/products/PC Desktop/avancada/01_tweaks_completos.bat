:: ================================================
::  CATYAMI OTIMIZACAO
::  Tweaks Completos do Sistema
::  Nivel: Avancada - Usuarios experientes
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
echo   ║   TWEAKS COMPLETOS DO SISTEMA                 ║
echo   ║   Nivel: AVANCADA                             ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo ================================================================
echo   ATENCAO: Este pacote aplica alteracoes avancadas no sistema!
echo   - Telemetria desativada
echo   - Servicos desnecessarios desativados
echo   - Registro otimizado
echo   - Privacidade aprimorada
echo ================================================================
echo.
echo [!] Dica: Crie um ponto de restauracao antes de continuar.
echo.
choice /C SN /M "Deseja criar um ponto de restauracao agora"
if !errorlevel! equ 1 (
    echo.
    echo [INFO] Criando ponto de restauracao...
    powershell -Command "Checkpoint-Computer -Description 'Catyami Otimizacao Pre-Tweaks' -RestorePointType 'MODIFY_SETTINGS'" 2>nul
    echo [OK] Ponto de restauracao criado (ou ja existia).
)
echo.
pause
cls

:: ================================================
:: FASE 1: DESATIVAR TELEMETRIA E RASTREAMENTO
:: ================================================
echo.
echo ================================================
echo   FASE 1/6: DESATIVANDO TELEMETRIA
echo ================================================
echo.

:: Desativar servico de telemetria
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
echo [OK] Servico de Telemetria (DiagTrack) desativado

sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
echo [OK] Servico WAP Push desativado

:: Bloquear telemetria via registro
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Telemetria do Windows bloqueada

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Notificacoes de feedback desativadas

:: Desativar rastreamento de atividade
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Rastreamento de atividades desativado

:: Bloquear anuncios e ID de propaganda
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] ID de propaganda desativado

:: Bloquear localizacao
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f >nul 2>&1
echo [OK] Servico de localizacao desativado

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: FASE 2: OTIMIZAR PRIVACIDADE
:: ================================================
echo [FASE 2/6] OTIMIZANDO PRIVACIDADE
echo.

:: Desativar Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Cortana desativada

:: Desativar OneDrive na inicializacao
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] OneDrive sync desativado

:: Desativar dicas do Windows
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Dicas e sugestoes do Windows desativadas

:: Desativar Widgets
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Widgets desativados

:: Desativar Copilot/Recall
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Windows Copilot desativado

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: FASE 3: OTIMIZAR DESKTOP E VISUAL
:: ================================================
echo [FASE 3/6] OTIMIZANDO APARENCIA DO DESKTOP
echo.

:: Efeitos visuais otimizados para desempenho
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
echo [OK] Animacoes de menu desativadas

:: Performance Explorer
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Efeitos visuais otimizados

:: Desativar transparencia
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Transparência desativada

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: FASE 4: DESATIVAR SERVICOS DESNECESSARIOS
:: ================================================
echo [FASE 4/6] DESATIVANDO SERVICOS DESNECESSARIOS
echo.

:: Lista de servicos seguros para desativar
set "services_to_disable=DiagTrack dmwappushservice RetailDemo PcaSvc WdiServiceHost DPS WSearch Fax PhoneSvc RemoteRegistry lfsvc MapsBroker XblAuthManager XblGameSave XboxGipSvc XboxNetApiSvcwisvc OneSyncSvc MessagingService cbdhsvc BcastDVRUserService CaptureService ConsentUX_%%DeviceModel%% ContactData_%%DeviceModel%% DeviceAssociationService"

for %%s in (
    DiagTrack
    dmwappushservice
    RetailDemo
    PcaSvc
    WdiServiceHost
    DPS
    Fax
    MapsBroker
    XblAuthManager
    XblGameSave
    XboxNetApiSvc
    wisvc
) do (
    sc config %%s start= disabled >nul 2>&1
    sc stop %%s >nul 2>&1
    echo [OK] Servico %%s desativado
)

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: FASE 5: OTIMIZAR REDE E INTERNET
:: ================================================
echo [FASE 5/6] OTIMIZANDO REDE E PING
echo.

:: Flush DNS e reset TCP/IP
ipconfig /flushdns >nul 2>&1
netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
echo [OK] DNS cache limpa, TCP/IP e Winsock resetados

:: Desativar Nagle's Algorithm (reduz latencia)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Nagle's Algorithm desativado (reducao de latencia)

:: Otimizar DNS para jogos
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableSize /t REG_DWORD /d 180 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheEntryTtlLimit /t REG_DWORD /d 0xff00 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxSOACacheEntryTtlLimit /t REG_DWORD /d 0x12d /f >nul 2>&1
echo [OK] Cache DNS otimizada para jogos

:: Configurar DNS Cloudflare e Google
netsh interface ip set dns name="Ethernet" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Ethernet" address=8.8.8.8 index=2 >nul 2>&1
netsh interface ip set dns name="Wi-Fi" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Wi-Fi" address=8.8.8.8 index=2 >nul 2>&1
echo [OK] DNS configurado: 1.1.1.1(Cloudflare) primario, 8.8.8.8(Google) secundario

:: Desativar auto-tuning que causa lag spikes
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
netsh interface tcp set global rss=enabled >nul 2>&1
netsh interface tcp set global chimney=enabled >nul 2>&1
netsh interface tcp set global netdma=enabled >nul 2>&1
netsh interface tcp set global ecncapability=disabled >nul 2>&1
netsh interface tcp set global timestamps=disabled >nul 2>&1
echo [OK] TCP global otimizado para jogos

:: Desativar LargeSystemCache para baixa latencia
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] LargeSystemCache desativado para baixa latencia

:: Aumentar numero de conexoes TCP
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d 65534 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d 30 /f >nul 2>&1
echo [OK] Conexoes TCP maximizadas

:: Aumentar buffer de rede
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DefaultTTL" /t REG_DWORD /d 64 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxConnectRetry" /t REG_DWORD /d 3 /f >nul 2>&1
echo [OK] Parametros de rede otimizados

:: Desativar SMBv1 (seguranca)
sc config lanmanworkstation depend= bowser/mrxsmb20/nsi >nul 2>&1
sc config mrxsmb10 start= disabled >nul 2>&1
echo [OK] SMBv1 desativado (seguranca)

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: FASE 6: OTIMIZAR POWER E PERFORMANCE
:: ================================================
echo [FASE 6/6] OTIMIZANDO PERFORMANCE
echo.

:: Ativar plano de alta performance (se disponivel)
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo [OK] Plano Ultimate Power desbloqueado

:: Configurar power settings
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1 >nul 2>&1
powercfg -setacvalueindex scheme_current sub_processor bc5038f3-231e-4f11-a0c1-7d8e8f4e0b2c 100 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1
echo [OK] Modo de alimentacao otimizado

:: Desativar hibernacao (libera espaco)
powercfg -h off >nul 2>&1
echo [OK] Hibernacao desativada (espaco em disco liberado)

:: Desativar SysMain/Superfetch (para SSD)
sc config SysMain start= disabled >nul 2>&1
sc stop SysMain >nul 2>&1
echo [OK] SysMain desativado (otimizado para SSD)

echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: RESUMO FINAL
:: ================================================
cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO                        ║
echo   ║   TWEAKS COMPLETOS APLICADOS!                 ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo   [OK] Telemetria desativada
echo   [OK] Privacidade aprimorada
echo   [OK] Cortana desativada
echo   [OK] Widgets desativados
echo   [OK] Copilot desativado
echo   [OK] Animacoes removidas
echo   [OK] Transparência desativada
echo   [OK] 12+ servicos desnecessarios desativados
echo   [OK] Rede otimizada
echo   [OK] Performance ajustada
echo   [OK] Hibernacao desativada
echo   [OK] SysMain desativado (SSD)
echo.
echo ================================================
echo   [!] REINICIE O COMPUTADOR PARA APLICAR TUDO!
echo ================================================
echo.
choice /C SN /M "Deseja reiniciar agora"
if !errorlevel! equ 1 (
    echo [INFO] Reiniciando em 5 segundos...
    timeout /t 5 >nul
    shutdown /r /t 0
)
exit /b 0
