@echo off
echo.
echo K6 Load Test Runner
echo ==================
echo.
echo Available test scripts:
echo 1. Catalog API Open Model Test (Read Operations)
echo 2. Catalog API Closed Model Test (Read Operations)
echo 3. Catalog API Closed Model Test (Read Operations, Quick Version 60s)
echo 4. Catalog API Closed Model Write Test (Write Operations)
echo 5. Catalog API Closed Model Write Test (Write Operations, Quick Version 60s)
echo 6. Exit
echo.
set /p choice="Choose a test (1-5): "

if "%choice%"=="1" (
    set SCRIPT_NAME=catalog-api-open-model-read-test.js
    goto runtest
)
if "%choice%"=="2" (
    set SCRIPT_NAME=catalog-api-closed-model-read-test.js
    goto runtest
)
if "%choice%"=="3" (
    set SCRIPT_NAME=catalog-api-closed-model-read-test-quick.js
    goto runtest
)
if "%choice%"=="4" (
    set SCRIPT_NAME=catalog-api-closed-model-write-test.js
    goto runtest
)
if "%choice%"=="5" (
    set SCRIPT_NAME=catalog-api-closed-model-write-test-quick.js
    goto runtest
)
if "%choice%"=="6" (
    echo Goodbye!
    goto end
)

echo Invalid choice. Please try again.
pause
goto :eof

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
powershell -Command "(Get-Content k8s\k6-job.yaml) -replace '/scripts/catalog-api-open-model-read-test.js', '/scripts/%SCRIPT_NAME%' | Set-Content k6-job-temp.yaml"

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