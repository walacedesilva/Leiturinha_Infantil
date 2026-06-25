@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"
echo Encerrando sessoes flutter/dart anteriores...
taskkill /f /im dart.exe >nul 2>&1
echo.
echo ===== Reconstruindo e instalando no aparelho via USB (debug) =====
call flutter devices
echo.
set "SERIAL="
for /f "skip=1 tokens=1" %%d in ('adb devices 2^>nul') do if not defined SERIAL set "SERIAL=%%d"
if defined SERIAL (
  echo Alvo USB: %SERIAL%
  call flutter run -d %SERIAL%
) else (
  echo Nenhum serial via adb. Rodando flutter run.
  call flutter run
)
echo.
echo ===== Processo finalizado. Pressione uma tecla para fechar. =====
pause >nul
