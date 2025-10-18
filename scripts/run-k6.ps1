Param(
    [string]$ScriptPath = "k6/scripts/catalog-api-closed-model-read-test.js",
    [string]$K6 = "k6"
)

Write-Host "Running k6 with script: $ScriptPath" -ForegroundColor Cyan

if (-not (Get-Command $K6 -ErrorAction SilentlyContinue)) {
    Write-Host "k6 not found on PATH. Please install k6: https://k6.io/docs/get-started/installation/" -ForegroundColor Red
    exit 1
}

# Show important context
Write-Host "Cluster context:" -ForegroundColor Yellow
try {
    kubectl config current-context | Out-Host
} catch {
    Write-Host "kubectl not available or no context set. Skipping." -ForegroundColor DarkYellow
}

Write-Host "Target URL:" -ForegroundColor Yellow
Write-Host "http://catalog-api.default.svc.cluster.local:8080/api/catalog/items?api-version=1.0" -ForegroundColor DarkCyan

# Execute k6
& $K6 run $ScriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "k6 run exited with code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "k6 run completed." -ForegroundColor Green

