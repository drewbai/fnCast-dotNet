param(
    [Parameter(Mandatory=$true)] [string] $ResourceGroup,
    [Parameter(Mandatory=$true)] [string] $TopicName,
    [string] $Subject = "fncast-demo",
    [string] $Data = "{ \"message\": \"hello from event grid\" }"
)

# Get topic endpoint and key
$topic = az eventgrid topic show --resource-group $ResourceGroup --name $TopicName --query "endpoint" -o tsv
$key = az eventgrid topic key list --resource-group $ResourceGroup --name $TopicName --query "key1" -o tsv

if (-not $topic -or -not $key) {
    Write-Error "Failed to resolve topic endpoint or key. Ensure topic exists."
    exit 1
}

# Build Event Grid schema event array
$events = @(
    @{ 
        id = [Guid]::NewGuid().ToString();
        eventType = "fncast.demo";
        subject = $Subject;
        eventTime = (Get-Date).ToString("o");
        data = (ConvertFrom-Json $Data);
        dataVersion = "1.0"
    }
) | ConvertTo-Json -Depth 5

# Publish
$headers = @{ "aeg-sas-key" = $key }
Write-Host "POST $topic"
Invoke-RestMethod -Method Post -Uri $topic -Headers $headers -Body $events -ContentType 'application/json'
Write-Host "Event published to topic '$TopicName'"
