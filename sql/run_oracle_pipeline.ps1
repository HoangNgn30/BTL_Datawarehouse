param([string]$Server='.\MSSQLSERVER01', [switch]$Trusted, [string]$User='')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
# Windows authentication by default; SQL auth takes the password only from the environment.
if (!$User) { $Trusted=$true }
if (!$Trusted -and !$env:SQLCMDPASSWORD) { throw 'SQL auth requires -User and SQLCMDPASSWORD environment variable.' }
$authArgs = @(if ($Trusted) { '-E' } else { '-U'; $User })
$env:DB_SERVER=$Server
$env:DB_TRUSTED=if($Trusted){'yes'}else{'no'}
$env:DB_CUSTOMER_SOURCE='STG_OracleVPDD'
if(!$Trusted){$env:DB_USER=$User;$env:DB_PASSWORD=$env:SQLCMDPASSWORD}
function Python-Step($script,$action='') {
    if($action){ & python "$root\scripts\$script" $action }else{ & python "$root\scripts\$script" }
    if($LASTEXITCODE -ne 0){throw "Failed: $script $action"}
}
function Sql-Step($file){
    & sqlcmd -S $Server @authArgs -C -b -f 65001 -v 'CustomerSource=STG_OracleVPDD' -i "$root\$file"
    if($LASTEXITCODE -ne 0){throw "Failed: $file"}
}
# Does not reset or seed either source. Oracle is the customer authority.
Python-Step 'oracle_sync.py' 'extract'
Python-Step 'oracle_sync.py' 'verify-stage'
Sql-Step 'sql\01c_integrate_idb.sql'
Sql-Step 'sql\02_etl_dw_core.sql'
Sql-Step 'sql\02b_dw_indexes.sql'
Sql-Step 'sql\03_prepare_olap.sql'
Sql-Step 'dw-dm\create_56_cuboids_vi.sql'
Sql-Step 'sql\04_metadata_indexes.sql'
Python-Step 'oracle_sync.py' 'verify'
Python-Step 'validate_olap.py'
Python-Step 'validate_reports.py'
Python-Step 'test_api.py'

Python-Step 'validate_idb.py'
