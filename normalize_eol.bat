@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"
if exist ".git\index.lock" del /f /q ".git\index.lock"
echo Branch atual:
git rev-parse --abbrev-ref HEAD
echo.
echo ===== Aplicando .gitattributes e renormalizando fim de linha =====
git add .gitattributes
git add --renormalize .
git commit -m "chore: normaliza fim de linha (LF) via .gitattributes"
echo.
echo ===== Status apos normalizacao (esperado: vazio/limpo) =====
git status -s
echo.
echo (Commit local apenas - nenhum push.)
echo Concluido. Pressione uma tecla para fechar.
pause >nul
