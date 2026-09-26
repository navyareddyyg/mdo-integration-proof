param(
    [Parameter(Mandatory)]
    [string] $BaselineScannerProject,

    [Parameter(Mandatory)]
    [string] $IntegratedScannerProject
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$fixtures = Join-Path $root 'fixtures'
$proofDirectory = Join-Path $root 'proof'
$baselineOutput = Join-Path $proofDirectory 'baseline.json'
$integratedOutput = Join-Path $proofDirectory 'integrated.json'

New-Item -ItemType Directory -Path $proofDirectory -Force | Out-Null

function Invoke-Scanner {
    param(
        [string] $Project,
        [string] $Output
    )

    $projectPath = if ([IO.Path]::IsPathRooted($Project)) {
        [IO.Path]::GetFullPath($Project)
    } else {
        [IO.Path]::GetFullPath((Join-Path $root $Project))
    }
    if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
        throw "Scanner project was not found: $projectPath"
    }

    dotnet run --project $projectPath -- $fixtures --output $Output --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "URL scanner failed with exit code $LASTEXITCODE."
    }
}

function Get-AcceptedMatches {
    param([string] $Path)

    $report = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    @(
        foreach ($file in @($report.files)) {
            foreach ($match in @($file.matches)) {
                [pscustomobject]@{
                    File = $file.path
                    Url = $match.url
                    Provenance = $match.howUrlFound
                }
            }
        }
    )
}

Invoke-Scanner -Project $BaselineScannerProject -Output $baselineOutput
Invoke-Scanner -Project $IntegratedScannerProject -Output $integratedOutput

$baseline = @(Get-AcceptedMatches -Path $baselineOutput)
$integrated = @(Get-AcceptedMatches -Path $integratedOutput)
$mdo = @($integrated | Where-Object Provenance -like 'MDO/*')
$fallback = @($integrated | Where-Object Provenance -like 'TI-Fallback/*')

$expected = @(
    'http://localhost:3000/health'
    'https://api[.]example[.]test/items?a=1&b=2'
    'https://cdn[.]example[.]test/app[.]js'
    'https://cdn[.]example[.]test/image[.]png'
    'https://custom[.]example[.]test/path/'
    'https://en[.]wikipedia[.]org/wiki/Function_(mathematics)'
    'https://fallback[.]example[.]test/path'
    'https://pkg[.]go[.]dev/badge/golang[.]org/x/example[.]svg'
    'https://pkg[.]go[.]dev/golang[.]org/x/example'
    'https://static[.]example[.]test/site[.]css'
    'https://strong[.]example[.]test/path/'
) | Sort-Object

$actual = @($integrated.Url | Sort-Object)
if (Compare-Object $expected $actual) {
    throw 'The integrated output did not match the expected URL set.'
}

$knownBaselineProblems = @(
    $baseline | Where-Object {
        $_.Url -eq 'http://localhost' -or
        $_.Url -like '*](*' -or
        $_.Url -match '\$\(|\$HOST|\{userId\}' -or
        $_.Url -like '*&amp;*'
    }
)

if ($baseline.Count -ne 13 -or $knownBaselineProblems.Count -ne 6) {
    throw 'The expected baseline behavior was not reproduced.'
}

if ($integrated.Count -ne 11 -or $mdo.Count -ne 8 -or $fallback.Count -ne 3) {
    throw 'The expected integrated result was not reproduced.'
}

Write-Host 'A/B comparison passed.'
Write-Host "Baseline:   $($baseline.Count) candidates, $($knownBaselineProblems.Count) known problems"
Write-Host "Integrated: $($integrated.Count) URLs, $($mdo.Count) MDO, $($fallback.Count) fallback"
