@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Energia

echo ========================================================
echo        CATYAMI NOTEBOOK - OTIMIZACAO DE ENERGIA
echo ========================================================
echo.

echo Ativando plano Alto Desempenho...
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo     [OK] Plano: Alto Desempenho

echo Desativando hibernacao no modo AC...
powercfg -change -standby-timeout-ac 0 >nul 2>&1
powercfg -change -hibernate-timeout-ac 0 >nul 2>&1
echo     [OK] Hibernacao desativada (AC)

echo Desligando tela mais rapido...
powercfg -change -monitor-timeout-ac 5 >nul 2>&1
echo     [OK] Monitor desliga em 5min (AC)

echo.
echo [REDE] Otimizando latencia WiFi...
ipconfig /flushdns >nul 2>&1
netsh interface tcp set global autotuninglevel=normal >nul 2>&1
echo     [OK] Rede otimizada

echo.
echo ========================================================
echo         ENERGIA OTIMIZADA PARA NOTEBOOK!
echo ========================================================
echo.
pause
