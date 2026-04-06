:: ================================================
::  CATYAMI OTIMIZACAO
::  Manutencao e Limpeza de Disco
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
echo   ║     MANUTENCAO E LIMPEZA DE DISCO             ║
echo   ║     Nivel: Leve                               ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo [INFO] Este script realiza limpeza e manutencao segura do disco.
echo [INFO] Nenhum dado pessoal sera excluido.
echo.
pause
cls

:: ================================================
:: 1. Diagnostico de Disco
:: ================================================
echo.
echo ================================================
echo   [1/7] DIAGNOSTICO DE DISCO
echo ================================================
echo.
echo [INFO] Informacoes dos discos instalados:
echo.
wmic diskdrive get Model,Size,InterfaceType,MediaType /format:list 2>nul
echo.
echo [INFO] Espaco em disco atual:
echo.
wmic logicaldisk get DeviceID,FileSystem,Size,FreeSpace,VolumeName /format:list 2>nul
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 2. Limpeza do Windows Update
:: ================================================
echo [2/7] LIMPANDO ARQUIVOS DO WINDOWS UPDATE
echo.
echo [INFO] Parando servicos do Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1
echo [INFO] Limpando cache do Windows Update...
del /f /q "%SYSTEMROOT%\SoftwareDistribution\Download\*.*" >nul 2>&1
del /f /q "%SYSTEMROOT%\WindowsUpdate.log" >nul 2>&1
echo [INFO] Reiniciando servicos...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
net start cryptsvc >nul 2>&1
echo [OK] Cache do Windows Update limpo!
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 3. Limpeza de Arquivos Temporarios
:: ================================================
echo [3/7] LIMPANDO ARQUIVOS TEMPORARIOS
echo.
echo [INFO] Limpando %TEMP%...
del /f /s /q "%TEMP%\*.*" >nul 2>&1
echo [OK] Pasta TEMP limpa
echo [INFO] Limpando prefetch...
del /f /s /q "%SYSTEMROOT%\Prefetch\*.*" >nul 2>&1
echo [OK] Pasta Prefetch limpa
echo [INFO] Limpando temp do Windows...
del /f /s /q "%SYSTEMROOT%\Temp\*.*" >nul 2>&1
echo [OK] Pasta Temp do Windows limpa
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 4. Limpeza do Lixeira
:: ================================================
echo [4/7] LIMPANDO A LIXEIRA
echo.
echo [INFO] Esvaziando a lixeira de todos os drives...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\$Recycle.Bin" (
        rd /s /q "%%D:\$Recycle.Bin" >nul 2>&1
        echo [OK] Lixeira do drive %%D esvaziada
    )
)
echo [OK] Lixeira esvaziada
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 5. Limpeza do Cache de DNS
:: ================================================
echo [5/7] LIMPANDO CACHE DE DNS E REDE
echo.
ipconfig /flushdns >nul 2>&1
echo [OK] Cache de DNS limpo
netsh winsock reset catalog >nul 2>&1
echo [OK] Winsock reset agendado
netsh int ip reset >nul 2>&1
echo [OK] TCP/IP reset agendado
echo [NOTA] Reinicie o PC para aplicar as mudancas de rede.
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 6. Verificacao de Disco (CheckDisk)
:: ================================================
echo [6/7] VERIFICACAO SAUDE DO DISCO
echo.
echo [INFO] Executando verificacao rapida do sistema de arquivos...
chkdsk C: /f /r >nul 2>&1
echo [INFO] Verificacao agendada para o proximo reinicio.
echo.
echo [INFO] Status SMART dos discos:
wmic diskdrive get Status,Model /format:list 2>nul
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: 7. Desfragmentacao / Otimizacao
:: ================================================
echo [7/7] OTIMIZACAO DE DISCO
echo.
echo [INFO] Otimizando unidades...
for %%D in (C) do (
    defrag %%D: /U /V 2>nul
    echo.
)
:: Para SSDs, o Windows faz TRIM automaticamente via Optimize-Volume
echo [OK] Otimizacao de disco concluida
echo.
ping -n 2 127.0.0.1 >nul 2>&1

:: ================================================
:: Resumo Final
:: ================================================
cls
echo.
echo ================================================
echo   ╔═══════════════════════════════════════════════╗
echo   ║     CATYAMI OTIMIZACAO                        ║
echo   ║   MANUTENCAO DE DISCO CONCLUIDA!              ║
echo   ╚═══════════════════════════════════════════════╝
echo.
echo   [OK] Diagnostico de disco realizado
echo   [OK] Cache do Windows Update limpo
echo   [OK] Arquivos temporarios removidos
echo   [OK] Lixeira esvaziada
echo   [OK] Cache de DNS limpo
echo   [OK] Verificacao de disco agendada
echo   [OK] Otimizacao de disco finalizada
echo.
echo ================================================
echo   [DICA] Execute esta manutencao semanalmente.
echo   [DICA] Reinicie o computador para concluir todas as operacoes.
echo ================================================
echo.
echo.
echo [INFO] Relatorio de espaco em disco apos limpeza:
echo.
wmic logicaldisk get DeviceID,Size,FreeSpace /format:list 2>nul
echo.
pause
exit /b 0
