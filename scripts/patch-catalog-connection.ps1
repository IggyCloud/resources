#
# This script patches the catalog-api-env ConfigMap to set the primary and replica DB connection strings.
#
param(
    [string]$Namespace = "default"
)

$ConfigMapName = "catalog-api-env"
$PrimaryKey = "ConnectionStrings__catalogdb"
$ReplicaKey = "ConnectionStrings__catalogdb_replica"

Write-Host "[catalog-conn] Reading base connection string from ConfigMap $ConfigMapName in namespace $Namespace..."

# Get the raw connection string from the existing ConfigMap
try {
    $conn_raw = kubectl -n $Namespace get configmap $ConfigMapName -o "jsonpath={.data.$PrimaryKey}"
}
catch {
    Write-Host "[catalog-conn] ERROR: Failed to get ConfigMap $ConfigMapName. Make sure aspirate has been run first."
    exit 1
}

if (-not $conn_raw) {
    Write-Host "[catalog-conn] ERROR: Base connection string '$PrimaryKey' missing or ConfigMap not found."
    exit 1
}

# Set the host to the primary service
$primary_conn = $conn_raw -replace 'Host=postgres', 'Host=postgres-primary-service'
$primary_conn = "$primary_conn;Maximum Pool Size=300;Timeout=15;Command Timeout=30"

# Create the replica connection string from the primary one
$replica_conn = $primary_conn -replace 'Host=postgres-primary-service', 'Host=postgres-replica-service'

# Create the JSON patch payload
$patch = @{
    data = @{
        "$PrimaryKey" = $primary_conn;
        "$ReplicaKey" = $replica_conn
    }
} | ConvertTo-Json -Compress -Depth 4

# Using a temporary file avoids PowerShell quoting issues with kubectl
$tempFile = [System.IO.Path]::GetTempFileName()
$patch | Out-File -FilePath $tempFile -Encoding utf8

Write-Host "[catalog-conn] Updating ConfigMap with primary and replica connection strings..."
try {
    kubectl patch configmap $ConfigMapName -n $Namespace --type merge --patch-file $tempFile
    Write-Host "[catalog-conn] Patch applied successfully."
}
catch {
    Write-Host "[catalog-conn] ERROR: kubectl patch command failed."
    # Re-throw the error to make the script fail
    throw
}
finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

Write-Host "[catalog-conn] Primary connection points to 'postgres-primary-service'."
Write-Host "[catalog-conn] Replica connection points to 'postgres-replica-service'."
