@echo off
cd /d "C:\Users\walace\Desktop\Leiturinha"
echo ===== Atualizando Leiturinha no aparelho USB (debug) =====
echo.
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
