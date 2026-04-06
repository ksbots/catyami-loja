@echo off
chcp 65001 >nul
color 0A
title Catyami NB - Bateria

echo ========================================================
echo        CATYAMI NOTEBOOK - DIAGNOSTICO DE BATERIA
echo ========================================================
echo.

echo Gerando relatorio de saude da bateria...
powercfg /batteryreport /output "%USERPROFILE%\catyami_battery_report.html"
echo     [OK] Relatorio gerado: %USERPROFILE%\catyami_battery_report.html

echo.
echo ========================================================
echo   DICAS PARA MAXIMA DURACAO DA BATERIA:
echo ========================================================
echo   - Mantenha brilho em 50%% ou menos
echo   - Feche apps em segundo plano
echo   - Modo Economia de Bateria do Windows
echo   - Evite carregar ate 100%% sempre (ideal: 20-80%%)
echo ========================================================
echo.
pause
