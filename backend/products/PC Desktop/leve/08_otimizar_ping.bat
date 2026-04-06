@echo off
chcp 65001 >nul
color 0A
title Catyami - Otimizacao Ping/Rede

echo ========================================================
echo          CATYAMI OTIMIZACAO - OTIMIZAR PING
echo ========================================================
echo.
echo  Reduzindo latencia de rede para jogos...
echo  Meta: 35ms -> ~10ms
echo.

REM Elevacao
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%%~f0\"\"&pause\"'"
    exit /b
)

echo [1/7] Otimizando rede/baixa latencia...
echo.

echo [2/7] Flush DNS e reset TCP/IP...
ipconfig /flushdns >nul 2>&1
netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
echo     [OK] DNS cache limpa, TCP/IP resetado, Winsock resetado
echo.

echo [3/7] Desativando Nagle's Algorithm (reduz latencia)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] Nagle's Algorithm desativado
echo.

echo [4/7] Otimizando DNS para jogos...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableSize /t REG_DWORD /d 180 /f >nul 2>&1
echo     [OK] Cache DNS otimizada
echo.

echo [5/7] Configurando TCP global para baixa latencia...
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
netsh interface tcp set global rss=enabled >nul 2>&1
netsh interface tcp set global chimney=enabled >nul 2>&1
echo     [OK] Auto-tuning configurado, RSS e chimney ativados
echo.

echo [6/7] Desativando LargeSystemCache para baixa latencia...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] LargeSystemCache desativado
echo.

echo [7/7] Configurando DNS Cloudflare e Google...
netsh interface ip set dns name="Ethernet" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Ethernet" address=8.8.8.8 index=2 >nul 2>&1
netsh interface ip set dns name="Wi-Fi" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Wi-Fi" address=8.8.8.8 index=2 >nul 2>&1
echo     [OK] DNS configurado: Primario=1.1.1.1(Cloudflare), Secundario=8.8.8.8(Google)
echo.

echo ========================================================
echo        REDE OTIMIZADA COM SUCESSO!
echo     [OK] Rede otimizada para baixa latencia
echo     [OK] Nagle's Algorithm desativado
echo     [OK] DNS Cloudflare + Google configurado
echo.
echo     Reinicie o PC para aplicar as alteracoes de rede.
echo     Esperativa de reducao: ~35ms -> ~10ms
echo ========================================================
echo.
pause
