param([string]$Server=".\MSSQLSERVER01", [string]$User="", [switch]$Trusted, [switch]$ResetDemo)
$ErrorActionPreference="Stop"
$root = Split-Path $PSScriptRoot -Parent
# Windows authentication by default; SQL auth takes the password only from the environment.
if (!$User) { $Trusted=$true }
if (!$Trusted -and !$env:SQLCMDPASSWORD) { throw 'SQL auth requires -User and SQLCMDPASSWORD environment variable.' }
$authArgs = @(if ($Trusted) { '-E' } else { '-U'; $User })
$resetValue = if ($ResetDemo) { '1' } else { '0' }
function Run($file) {
    Write-Host ">> $file"
    & sqlcmd -S $Server @authArgs -C -b -f 65001 -v "ResetDemo=$resetValue" "CustomerSource=IDB_VPDD" -i $file
    if ($LASTEXITCODE -ne 0) { throw "Loi khi chay $file" }
}
Run "$root\sql\01_idb_source.sql"
Run "$root\sql\01b_inventory_source.sql"
Run "$root\sql\01c_integrate_idb.sql"
Run "$root\sql\02_etl_dw_core.sql"
Run "$root\sql\02b_dw_indexes.sql"
Run "$root\sql\03_prepare_olap.sql"
Run "$root\dw-dm\create_56_cuboids_vi.sql"
Run "$root\sql\04_metadata_indexes.sql"
$env:DB_CUSTOMER_SOURCE='IDB_VPDD'
$env:DB_SERVER=$Server
$env:DB_TRUSTED=if ($Trusted) { 'yes' } else { 'no' }
if (!$Trusted) { $env:DB_USER=$User; $env:DB_PASSWORD=$env:SQLCMDPASSWORD }
& python "$root\scripts\validate_olap.py"
if ($LASTEXITCODE -ne 0) { throw 'Doi chieu du lieu that bai.' }

& python "$root\scripts\validate_reports.py"
if ($LASTEXITCODE -ne 0) { throw 'Doi chieu 9 bao cao that bai.' }
& python "$root\scripts\test_api.py"
if ($LASTEXITCODE -ne 0) { throw 'Kiem tra API that bai.' }

& python "$root\scripts\validate_idb.py"
if ($LASTEXITCODE -ne 0) { throw "IDB/metadata/index validation failed" }
