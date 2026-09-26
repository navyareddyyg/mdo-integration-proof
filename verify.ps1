param(
    [Parameter(Mandatory)]
    [string] $ScannerProject
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$fixtures = Join-Path $root 'fixtures'
$proofDirectory = Join-Path $root 'proof'
$output = Join-Path $proofDirectory 'integrated.json'
$projectPath = if ([IO.Path]::IsPathRooted($ScannerProject)) {
    [IO.Path]::GetFullPath($ScannerProject)
} else {
    [IO.Path]::GetFullPath((Join-Path $root $ScannerProject))
}

if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
    throw "Scanner project was not found: $projectPath"
}

New-Item -ItemType Directory -Path $proofDirectory -Force | Out-Null

dotnet run --project $projectPath -- $fixtures --output $output --quiet
if ($LASTEXITCODE -ne 0) {
    throw "URL scanner failed with exit code $LASTEXITCODE."
}

$report = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
$matches = @(
    foreach ($file in @($report.files)) {
        foreach ($match in @($file.matches)) {
            Write-Output -NoEnumerate $match
        }
    }
)
$mdo = @($matches | Where-Object howUrlFound -like 'MDO/*')
$fallback = @($matches | Where-Object howUrlFound -like 'TI-Fallback/*')
$unexpected = @(
    $matches | Where-Object url -match 'localhost|version|HOST|userId'
)

if ($matches.Count -ne 11 -or $mdo.Count -ne 8 -or $fallback.Count -ne 3) {
    throw 'The expected integrated counts were not reproduced.'
}

if ($unexpected.Count -ne 1 -or $unexpected[0].url -notmatch 'localhost.*3000') {
    throw 'An unresolved source-code placeholder was accepted.'
}

Write-Host 'Integration proof passed.'
Write-Host "Accepted URLs: $($matches.Count)"
Write-Host "MDO primary:   $($mdo.Count)"
Write-Host "Fallback:      $($fallback.Count)"
