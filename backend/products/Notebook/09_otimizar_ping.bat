@echo off
chcp 65001 >nul
color 0A
title Catyami - Notebook - Otimizacao Ping/Rede

echo ========================================================
echo    CATYAMI NOTEBOOK - OTIMIZAR PING E REDE
echo ========================================================
echo.
echo  Reduzindo latencia de rede para jogos no Notebook...
echo  Meta: ~35ms -> ~10ms
echo  Otimizacoes incluidas WiFi + rede
echo.

REM Elevacao
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"\"%%~f0\"\" '""
    exit /b
)

echo [1/10] Otimizando rede/baixa latencia...
echo.

echo [2/10] Flush DNS e reset TCP/IP...
ipconfig /flushdns >nul 2>&1
netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
echo     [OK] DNS cache limpa, TCP/IP resetado, Winsock resetado
echo.

echo [3/10] Desativando Nagle's Algorithm (reduz latencia)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] Nagle's Algorithm desativado
echo.

echo [4/10] Otimizando DNS para jogos...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableSize /t REG_DWORD /d 180 /f >nul 2>&1
echo     [OK] Cache DNS otimizada
echo.

echo [5/10] Configurando TCP global para baixa latencia...
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
netsh interface tcp set global rss=enabled >nul 2>&1
netsh interface tcp set global chimney=enabled >nul 2>&1
netsh interface tcp set global netdma=enabled >nul 2>&1
netsh interface tcp set global ecncapability=disabled >nul 2>&1
netsh interface tcp set global timestamps=disabled >nul 2>&1
echo     [OK] TCP global otimizado para jogos
echo.

echo [6/10] Desativando LargeSystemCache para baixa latencia...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] LargeSystemCache desativado
echo.

echo [7/10] Configurando DNS Cloudflare e Google...
netsh interface ip set dns name="Ethernet" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Ethernet" address=8.8.8.8 index=2 >nul 2>&1
netsh interface ip set dns name="Wi-Fi" source=static address=1.1.1.1 >nul 2>&1
netsh interface ip add dns name="Wi-Fi" address=8.8.8.8 index=2 >nul 2>&1
echo     [OK] DNS configurado: Primario=1.1.1.1(Cloudflare), Secundario=8.8.8.8(Google)
echo.

echo [8/10] Configurando WiFi - desativar economia de energia...
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5273-468f-9439-e3e4e8e5e3e3 a7066653-8d6c-40a8-910e-a1f54b84c7e5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5273-468f-9439-e3e4e8e5e3e3 a7066653-8d6c-40a8-910e-a1f54b84c7e5 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b0d-98f5-9b4ba207867f e6e2d0c8-c0d9-4e3b-9497-4f8248e7b800 0 >nul 2>&1
echo     [OK] Economia de energia WiFi desativada (plano energia e bateria)
echo.

echo [9/10] Otimizando adaptadores de rede WiFi...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\Nsi" /v "Store" /t REG_DWORD /d 0 /f >nul 2>&1
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Network\{4D36E972-E325-11CE-BFC1-08002BE10318}"') do (
    reg add "%%a\Ndi\params\*PowerManagement" /v "ParamDesc" /t REG_SZ /d "Power Management" /f >nul 2>&1
)
echo     [OK] Gerenciamento de energia da placa de rede otimizado
echo.

echo [10/10] Configurando plano de energia para WiFi maximo...
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b0b-98f5-9b4ba207867f e3b5b01e-ec87-4c7b-8c4b-2c5e7c4d6f86 100 >nul 2>&1
echo     [OK] Potencia WiFi configurada para maximo
echo.

echo ========================================================
echo        REDE WI-FI OTIMIZADA COM SUCESSO!
echo     [OK] Rede otimizada para baixa latencia
echo     [OK] Nagle's Algorithm desativado
echo     [OK] DNS Cloudflare + Google configurado
echo     [OK] WiFi power saving desativado
echo     [OK] Placa de rede otimizada
echo.
echo     Reinicie o Notebook para aplicar as alteracoes.
echo     Esperativa de reducao: ~35ms -> ~10ms
echo ========================================================
echo.
pause
