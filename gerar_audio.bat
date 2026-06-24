@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"
echo ===== Instalando edge-tts (voz neural pt-BR) =====
py -m pip install --quiet --upgrade edge-tts
if errorlevel 1 (
  echo [ERRO] Nao foi possivel instalar o edge-tts. Verifique Python/internet.
  pause & exit /b 1
)
echo.
echo ===== Teste rapido (gera "ba" e "casa") =====
py tools\gen_audio.py teste
echo.
echo Se os 2 testes acima deram "ok", vou gerar TUDO (76 silabas + 88 palavras).
pause
echo.
echo ===== Gerando todos os audios =====
py tools\gen_audio.py
echo.
echo ===== Concluido. Rode o app (run_usb.bat) para ouvir. =====
pause
