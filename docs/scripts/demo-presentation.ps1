param(
    [ValidateSet('api','functions-http','functions-eg','functions-queue','all','help')]
    [string]$Mode = 'all',
    [string]$ApiBaseUrl = 'http://localhost:5000',
    [string]$FunctionsBaseUrl = 'http://localhost:7071',
    [string]$ResourceGroup,
    [string]$TopicName,
    [string]$StorageAccountName,
    [string]$QueueName = 'fncast-events',
    [string]$ConnectionString,
    [string]$Subject = 'demo',
    [string]$Message = 'hello',
    [string]$Data = '{"message":"hello"}'
)

function Write-Section([string]$text) {
    Write-Host "`n=== $text ===" -ForegroundColor Cyan
}
function Write-Ok([string]$text) { Write-Host $text -ForegroundColor Green }
function Write-Warn([string]$text) { Write-Host $text -ForegroundColor Yellow }
function Write-Err([string]$text) { Write-Host $text -ForegroundColor Red }

function Invoke-MinimalApiIngest() {
    Write-Section "Minimal API: POST /ingest"
    $uri = "$ApiBaseUrl/ingest"
    $body = @{ content = $Message; contentType = 'text/plain'; source = 'demo' } | ConvertTo-Json -Depth 3
    try {
        $res = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json'
        Write-Ok "Response: $(ConvertTo-Json $res)"
    } catch {
        Write-Err "API request failed: $($_.Exception.Message)"
    }
}

function Invoke-FunctionsHttpIngest() {
    Write-Section "Functions HTTP: POST /api/HttpIngest"
    $uri = "$FunctionsBaseUrl/api/HttpIngest"
    $body = @{ content = $Message; contentType = 'text/plain'; source = 'demo' } | ConvertTo-Json -Depth 3
    try {
        $res = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json'
        Write-Ok "Response: $(ConvertTo-Json $res)"
    } catch {
        Write-Err "Functions HTTP failed: $($_.Exception.Message)"
    }
}

function Publish-EventGridDemo() {
    Write-Section "Event Grid: Publish to topic"
    if (-not $ResourceGroup -or -not $TopicName) {
        Write-Warn "Missing -ResourceGroup or -TopicName; skipping Event Grid publish"
        return
    }
    $script = Join-Path $PSScriptRoot 'publish-eventgrid.ps1'
    if (-not (Test-Path $script)) { Write-Err "Helper script not found: $script"; return }
    & $script -ResourceGroup $ResourceGroup -TopicName $TopicName -Subject $Subject -Data $Data
}

function Publish-QueueDemo() {
    Write-Section "Storage Queue: Send message"
    $script = Join-Path $PSScriptRoot 'publish-queue-message.ps1'
    if (-not (Test-Path $script)) { Write-Err "Helper script not found: $script"; return }
    $params = @{ QueueName = $QueueName; Message = $Message }
    if ($ConnectionString) {
        $params.ConnectionString = $ConnectionString
    } else {
        if (-not $ResourceGroup -or -not $StorageAccountName) {
            Write-Warn "Missing -ResourceGroup or -StorageAccountName; skipping Queue publish"
            return
        }
        $params.ResourceGroup = $ResourceGroup
        $params.StorageAccountName = $StorageAccountName
    }
    & $script @params
}

if ($Mode -eq 'help') {
    Write-Host "Usage: demo-presentation.ps1 [-Mode api|functions-http|functions-eg|functions-queue|all|help] [-ApiBaseUrl URL] [-FunctionsBaseUrl URL] [-ResourceGroup RG] [-TopicName NAME] [-StorageAccountName NAME] [-QueueName NAME] [-ConnectionString CS] [-Subject subj] [-Message msg] [-Data json]" -ForegroundColor Cyan
    exit 0
}

switch ($Mode) {
    'api' { Invoke-MinimalApiIngest }
    'functions-http' { Invoke-FunctionsHttpIngest }
    'functions-eg' { Publish-EventGridDemo }
    'functions-queue' { Publish-QueueDemo }
    'all' {
        Invoke-MinimalApiIngest
        Invoke-FunctionsHttpIngest
        Publish-EventGridDemo
        Publish-QueueDemo
    }
}

Write-Ok "Done. For details, see README Producer Scripts section."
