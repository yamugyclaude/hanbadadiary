@echo off
chcp 65001 > nul
echo.
echo  ╔══════════════════════════════════════╗
echo  ║     한바다 작업일지  시작           ║
echo  ╚══════════════════════════════════════╝
echo.
echo  [1/2] 최신 코드를 받아오는 중...
echo.
git pull origin main
echo.
echo  [2/2] 완료!
echo.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  이제 Claude Code 앱을 열고
echo  이 폴더를 프로젝트로 선택하세요.
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
pause
