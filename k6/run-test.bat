@echo off
echo.
echo K6 Load Test Runner
echo ==================
echo.
echo Available test scripts:
echo 1. Catalog API Open Model Test
echo 2. Catalog API Closed Model Test
echo 3. Exit
echo.
set /p choice="Choose a test (1-3): "

if "%choice%"=="1" (
    set SCRIPT_NAME=catalog-api-open-model-test.js
    goto runtest
)
if "%choice%"=="2" (
    set SCRIPT_NAME=catalog-api-closed-model-test.js
    goto runtest
)
if "%choice%"=="3" (
    echo Goodbye!
    goto end
)

echo Invalid choice. Please try again.
pause
goto start

:runtest
echo.
echo Running K6 test with script: %SCRIPT_NAME%
echo.

REM Delete existing job and configmap
kubectl delete job k6-load-test -n k6-loadtest --ignore-not-found=true
kubectl delete configmap k6-scripts -n k6-loadtest --ignore-not-found=true

REM Create ConfigMap from scripts directory
kubectl create configmap k6-scripts --from-file=scripts/ -n k6-loadtest

REM Create temporary job file with the script name substituted
powershell -Command "(Get-Content k8s\k6-job.yaml) -replace '/scripts/catalog-api-open-model-test.js', '/scripts/%SCRIPT_NAME%' | Set-Content k6-job-temp.yaml"

REM Create new k6 job
kubectl apply -f k6-job-temp.yaml

REM Clean up temporary file
del k6-job-temp.yaml

echo.
echo K6 test started successfully!
echo.
echo Monitor with: kubectl logs -f job/k6-load-test -n k6-loadtest
echo View results: http://localhost:30300
echo.
pause

:end