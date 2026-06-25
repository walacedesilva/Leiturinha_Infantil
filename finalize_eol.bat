@echo off
chcp 65001 >nul
cd /d "C:\Users\walace\Desktop\Leiturinha"
if exist ".git\index.lock" del /f /q ".git\index.lock"
echo Branch atual:
git rev-parse --abbrev-ref HEAD
echo.
echo ===== Adicionando e renormalizando (remove byte NUL, aplica LF) =====
git add -A
git add --renormalize .
git commit -m "chore: remove byte NUL e normaliza EOL (main, nav_shell, login)"
echo.
echo ===== Status final (esperado: limpo) =====
git status -s
echo.
echo (Commit local apenas - nenhum push.)
echo Concluido. Pressione uma tecla para fechar.
pause >nul
