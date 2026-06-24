@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"

echo ===== 1/3 Preparando repositorio =====
if exist ".git\index.lock" (
  echo Removendo index.lock antigo...
  del /f /q ".git\index.lock"
)
echo.

echo ===== 2/3 Criando branch feature/fluxo-entrada e commitando =====
git rev-parse --verify feature/fluxo-entrada >nul 2>&1
if %errorlevel%==0 (
  echo A branch ja existe. Mudando para ela...
  git checkout feature/fluxo-entrada
) else (
  git checkout -b feature/fluxo-entrada
)
if errorlevel 1 (
  echo.
  echo [ERRO] Nao foi possivel criar/trocar a branch. Abortando.
  pause
  exit /b 1
)

git add -A
git commit -m "feat: novo fluxo de entrada (Login + Onboarding) em retrato com mascote Leo"
echo.
echo Branch atual:
git rev-parse --abbrev-ref HEAD
echo (Commit local apenas - nenhum push foi feito.)
echo.

echo ===== 3/3 Atualizando aparelho via USB (debug) =====
echo Dispositivos detectados:
call flutter devices
echo.
set "SERIAL="
for /f "skip=1 tokens=1" %%d in ('adb devices 2^>nul') do if not defined SERIAL set "SERIAL=%%d"
if defined SERIAL (
  echo Alvo USB: %SERIAL%
  call flutter run -d %SERIAL%
) else (
  echo Nenhum serial via adb. Rodando flutter run ^(escolha o aparelho se for pedido^).
  call flutter run
)
echo.
echo ===== Processo finalizado. Pressione uma tecla para fechar. =====
pause >nul
