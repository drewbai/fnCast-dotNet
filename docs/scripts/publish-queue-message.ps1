param(
    [string] $ConnectionString,
    [string] $ResourceGroup,
    [string] $StorageAccountName,
    [string] $QueueName = "fncast-events",
    [Parameter(Mandatory=$true)] [string] $Message
)

if (-not $ConnectionString) {
    if (-not $ResourceGroup -or -not $StorageAccountName) {
        Write-Error "Provide either -ConnectionString or (-ResourceGroup and -StorageAccountName)."
        exit 1
    }
    $key = az storage account keys list -g $ResourceGroup -n $StorageAccountName --query "[0].value" -o tsv
    if (-not $key) { Write-Error "Failed to fetch storage account key."; exit 1 }
    $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$key;EndpointSuffix=core.windows.net"
}

# Create queue if not exists
az storage queue create --name $QueueName --connection-string "$ConnectionString" 1>$null

# Put message
az storage message put --queue-name $QueueName --content "$Message" --connection-string "$ConnectionString"
Write-Host "Message published to queue '$QueueName'"
