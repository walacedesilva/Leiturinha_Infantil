@echo off
echo Mantendo a tela do celular sempre ligada enquanto conectado via USB...
adb shell svc power stayon true
echo.
echo Pronto! A tela nao vai mais apagar enquanto o cabo estiver conectado.
echo Para reverter depois, rode: adb shell svc power stayon false
echo.
pause
