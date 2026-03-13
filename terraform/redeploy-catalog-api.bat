@echo off
setlocal

:: Get the root directory of the repository (two levels up from resources/terraform)
set REPO_ROOT=%~dp0..\..
cd /d "%REPO_ROOT%"

echo [1/2] Building Catalog.API Docker image...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "./resources/terraform/build-catalog-api.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed. Aborting redeploy.
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Triggering Kubernetes rollout restart...
kubectl rollout restart deployment catalog-api

echo.
echo [DONE] Redeploy triggered. Checking status...
kubectl rollout status deployment catalog-api

pause
