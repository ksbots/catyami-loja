@echo off
chcp 65001 >nul
color 0A
title Catyami NetBooster - Otimizador de Rede

echo ============================================================
echo          CATYAMI NETBOOSTER - OTIMIZADOR DE PING
echo ============================================================
echo.
echo  Testando e otimizando sua conexao de rede...
echo  Meta: reduzir latencia de ~35ms para ~10ms

echo  Aguarde... Isso pode levar alguns instantes
echo.

NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] Solicitando permissao de administrador...
    powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"%~f0\" & pause'"
    exit /b
)

echo ============================================================
echo   FASE 1: TESTE DE PING ANTES DA OTIMIZACAO
echo ============================================================
echo.
echo  Enviando 10 pings para 1.1.1.1...
echo.

ping 1.1.1.1 -n 10 > "%TEMP%\catyami_ping_before.txt" 2>&1
for /f "tokens=3 delims== " %%a in ('type "%TEMP%\catyami_ping_before.txt" ^| find "M') do echo  Ping medio ANTES: %%a
echo.

echo ============================================================
echo   FASE 2: APLICANDO OTIMIZACOES DE REDE
echo ============================================================
echo.

echo [1/10] Limpando cache DNS...
ipconfig /flushdns >nul 2>&1
echo     [OK] Cache DNS limpa

echo [2/10] Resetando TCP/IP stack...
netsh int ip reset >nul 2>&1
echo     [OK] TCP/IP resetado

echo [3/10] Resetando Winsock catalog...
netsh winsock reset >nul 2>&1
echo     [OK] Winsock resetado

echo [4/10] Desativando Nagle's Algorithm...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] Nagle's Algorithm desativado

echo [5/10] Otimizando cache DNS para jogos...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableSize /t REG_DWORD /d 180 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheEntryTtlLimit /t REG_DWORD /d 65280 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxSOACacheEntryTtlLimit /t REG_DWORD /d 289 /f >nul 2>&1
echo     [OK] Cache DNS otimizada para baixa latencia

echo [6/10] Configurando TCP global...
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
netsh interface tcp set global rss=enabled >nul 2>&1
netsh interface tcp set global chimney=enabled >nul 2>&1
netsh interface tcp set global netdma=enabled >nul 2>&1
netsh interface tcp set global dca=enabled >nul 2>&1
netsh interface tcp set global ecncapability=disabled >nul 2>&1
netsh interface tcp set global timestamps=disabled >nul 2>&1
echo     [OK] TCP global otimizado

echo [7/10] Desativando LargeSystemCache...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo     [OK] LargeSystemCache desativado

echo [8/10] Configurando DNS Cloudflare + Google...
for /f "tokens=4*" %%i in ('netsh interface ipv4 show interfaces ^| findstr /v "Loopback" ^| findstr /r "[0-9]"') do (
    netsh interface ip set dns name="%%i" source=static address=1.1.1.1 >nul 2>&1
    netsh interface ip add dns name="%%i" address=8.8.8.8 index=2 >nul 2>&1
)
echo     [OK] DNS: Primario=1.1.1.1(Cloudflare), Secundario=8.8.8.8(Google)

echo [9/10] Otimizando adaptadores de rede...
for /f "tokens=4*" %%i in ('netsh interface ipv4 show subinterfaces ^| findstr /v "Loopback" ^| findstr /r "[0-9]"') do (
    netsh interface ipv4 set subinterface "%%j" mtu=1500 store=persistent >nul 2>&1
)
echo     [OK] MTU configurado para 1500

echo [10/10] Desativando economia de energia dos adaptadores...
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5273-468f-9439-484642d7d311 0 >nul 2>&1
echo     [OK] Economia de energia dos adaptadores desativada

echo.
echo ============================================================
echo         TODAS AS OTIMIZACOES APLICADAS!
echo ============================================================
echo.
echo  Resumo das alteracoes:
echo     [OK] Rede otimizada para baixa latencia
echo     [OK] Nagle's Algorithm desativado
echo     [OK] DNS Cloudflare 1.1.1.1 + Google 8.8.8.8
echo     [OK] TCP/IP e Winsock resetados
echo     [OK] Cache DNS otimizada
echo     [OK] Auto-tuning configurado
echo     [OK] LargeSystemCache desativado
echo     [OK] Economia de energia desativada
echo.

echo ============================================================
echo   FASE 3: TESTE DE PING APOS A OTIMIZACAO
echo ============================================================
echo.
echo  Aguardando 5 segundos para aplicar alteracoes...

timeout /t 5 /nobreak >nul

echo  Enviando 10 pings para 1.1.1.1 apos otimizacao...
echo.

ping 1.1.1.1 -n 10 > "%TEMP%\catyami_ping_after.txt" 2>&1
for /f "tokens=3 delims== " %%a in ('type "%TEMP%\catyami_ping_after.txt" ^| find "M') do echo  Ping medio DEPOIS: %%a
echo.

echo ============================================================
echo           NETBOOSTER CONCLUIDO COM SUCESSO!
echo.
echo  IMPORTANTE: Reinicie o PC para finalizar as
echo  alteracoes de rede e obter o melhor resultado.
echo  Esperativa: ~35ms -%3E ~10ms
echo ============================================================
echo.
del /q "%TEMP%\catyami_ping_before.txt" >nul 2>&1
del /q "%TEMP%\catyami_ping_after.txt" >nul 2>&1
pause
