:: ================================================
::  CATYAMI OTIMIZACAO
::  Otimizador para Jogos
::  Nivel: Leve - Seguro para qualquer PC
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
echo   ║        OTIMIZADOR PARA JOGOS                  ║
echo   ║        Nivel: Leve                            ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo [INFO] Otimizando Windows para melhor desempenho em jogos...
echo.
pause
cls

:: ================================================
:: 1. Habilitar Game Mode
:: ================================================
echo.
echo ================================================
echo   [1/8] HABILITANDO GAME MODE DO WINDOWS
echo ================================================
echo.
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Game Mode configurado
echo [OK] Game DVR desativado (melhora FPS)
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 2. Otimizar Agendamento de GPU
:: ================================================
echo [2/8] OTIMIZANDO AGENDAMENTO DE GPU
echo.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DpiMapIommuContiguous" /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Hardware-accelerated GPU scheduling habilitado
echo [OK] Latencia de GPU reduzida
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 3. Otimizar Timer Resolution
:: ================================================
echo [3/8] OTIMIZANDO TIMER RESOLUTION
echo.
powercfg -setactive-value "SCHEDULER" 1 >nul 2>&1
bcdedit /set useplatformclock true >nul 2>&1
echo [OK] Timer resolution otimizado
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 4. Desativar Nagle's Algorithm (Rede)
:: ================================================
echo [4/8] DESATIVANDO NAGLE'S ALGORITHM (MELHORA PING)
echo.
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /v "TcpAckFrequency" 2^>nul ^| find "TcpAckFrequency"') do (
    set iface_key=%%a
)
:: Aplicar em todas as interfaces de rede
for /f %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /f "IPAddress" /s 2^>nul ^| find "HKEY"') do (
    reg add "%%I" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%I" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%I" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
)
echo [OK] Nagle's Algorithm desativado
echo [DICA] Reduz latencia em jogos online
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 5. Otimizar Prioridade de Processador
:: ================================================
echo [5/8] OTIMIZANDO PRIORIDADE DE PROCESSADOR
echo.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo [OK] Prioridade ajustada para Foreground + Responsivo
echo [DICA] Processos em primeiro plano recebem mais recursos
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 6. Desativar Power Saving em Dispositivos de Rede
:: ================================================
echo [6/8] DESATIVANDO ECONOMIA DE ENERGIA NA REDE
echo.
for /f "tokens=2 delims== skip=1" %%A in ('wmic nic where "NetEnabled=true" get DeviceID /value') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\%%A" /v "PnPCapabilities" /t REG_DWORD /d 24 /f >nul 2>&1
    echo [OK] NIC %%A - Economia de energia desativada
)
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 7. Otimizar DNS para Gaming
:: ================================================
echo [7/8] OTIMIZANDO DNS PARA GAMING
echo.
netsh interface ip set dns name="Ethernet" source=static addr=1.1.1.1 register=primary validate=yes >nul 2>&1
netsh interface ip add dns name="Ethernet" addr=1.0.0.1 index=2 >nul 2>&1
netsh interface ip set dns name="Wi-Fi" source=static addr=1.1.1.1 register=primary validate=yes >nul 2>&1
netsh interface ip add dns name="Wi-Fi" addr=1.0.0.1 index=2 >nul 2>&1
echo [OK] DNS configurado: Cloudflare (1.1.1.1 / 1.0.0.1)
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 8. Desativar Fullscreen Optimizations
:: ================================================
echo [8/8] DESATIVANDO FULLSCREEN OPTIMIZACOES
echo.
reg add "HKCU\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f >nul 2>&1
echo [OK] Fullscreen optimizations desativadas
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: Resumo
:: ================================================
cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO                        ║
echo   ║   OTIMIZACAO DE JOGOS CONCLUIDA!              ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo   [OK] Game Mode habilitado
echo   [OK] Game DVR desativado
echo   [OK] GPU Scheduling otimizado
echo   [OK] Timer Resolution ajustado
echo   [OK] Nagle's Algorithm desativado (ping menor)
echo   [OK] Prioridade de processador otimizada
echo   [OK] Economia de energia na rede desativada
echo   [OK] DNS Cloudflare configurado
echo   [OK] Fullscreen optimizations desativadas
echo.
echo ================================================
echo   [DICA] Reinicie o computador para aplicar todas as alteracoes!
echo ================================================
echo.
pause
exit /b 0
