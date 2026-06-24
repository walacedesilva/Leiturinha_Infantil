@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"
if exist ".git\index.lock" del /f /q ".git\index.lock"
echo Branch atual:
git rev-parse --abbrev-ref HEAD
git add -A
git commit -m "fix(retrato): LandscapeStage nas telas de gameplay para evitar overflow + helper"
echo.
echo (Commit local apenas - nenhum push.)
echo Concluido. Pressione uma tecla para fechar.
pause >nul
