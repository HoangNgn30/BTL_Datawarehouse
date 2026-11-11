param([switch]$BootstrapDemo,[string]$Server='.\MSSQLSERVER01')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$secretDir=Join-Path $PSScriptRoot 'secrets'
New-Item -ItemType Directory -Force $secretDir | Out-Null
foreach($name in @('admin_password','app_password')){
    $target=Join-Path $secretDir $name
    if(!(Test-Path -LiteralPath $target)){
        $bytes=New-Object byte[] 24
        $rng=[System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($bytes)
        $rng.Dispose()
        $secret='Kdl9_'+[BitConverter]::ToString($bytes).Replace('-','')
        [System.IO.File]::WriteAllText($target,$secret)
    }
}
& docker compose -f "$PSScriptRoot\compose.yaml" up -d
if($LASTEXITCODE -ne 0){throw 'Oracle container startup failed.'}
$deadline=(Get-Date).AddMinutes(10)
do{
    $health=& docker inspect kdl-oracle --format '{{.State.Health.Status}}'
    if($health -eq 'healthy'){break}
    if((Get-Date) -gt $deadline){throw 'Oracle startup timed out. Check docker logs kdl-oracle.'}
    Start-Sleep -Seconds 5
}while($true)
Write-Host 'Oracle healthy: 127.0.0.1:1522/FREEPDB1; schema KDL_VPDD.'
if($BootstrapDemo){
    $env:DB_SERVER=$Server
    $env:DB_TRUSTED='yes'
    & python "$root\scripts\oracle_sync.py" bootstrap-demo
    if($LASTEXITCODE -ne 0){throw 'Oracle demo bootstrap failed or source already exists.'}
}
