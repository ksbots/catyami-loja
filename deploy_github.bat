@echo off
chcp 65001 >nul
title Catyami - Deploy GitHub Pages

echo ============================================================
echo            CATYAMI - DEPLOY PARA GitHub
echo ============================================================
echo.

cd /d "%~dp0"

REM Verificar git
git --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Git nao encontrado. Instale: https://git-scm.com
    pause
    exit /b 1
)

REM Verificar gh
gh auth status >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [!] GitHub CLI nao autenticado.
    echo.
    echo Execute: gh auth login
    echo.
    echo Depois rode este script novamente.
    pause
    exit /b 1
)

echo [1/4] Adicionando arquivos ao git...
git add .

echo [2/4] Fazendo commit...
git commit -m "deploy: loja completa com carrinho, admin, checkout pix"

echo [3/4] Criando repositorio no GitHub...
gh repo create catyami-loja --public --source=. --remote=upstream --push
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo [!] Repositorio pode ja existir. Tentando push...
)

echo [4/4] Fazendo push...
git push --force

echo.
echo ============================================================
echo        DEPLOY CONCLUIDO!
echo ============================================================
echo.
echo  Agora ative GitHub Pages:
echo  1. Va ao repositorio no GitHub
echo  2. Settings ^> Pages
echo  3. Source: Deploy from branch
echo  4. Branch: main / (root)
echo  5. Salve
echo.
echo  O site fica em:
echo  https://SEU_USERNAME.github.io/catyami-loja/
echo ============================================================
echo.
pause
