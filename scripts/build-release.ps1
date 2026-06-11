$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ModDir = Join-Path $RepoRoot "SolarpunkPauseOnMenu"
$SignaturesDir = Join-Path $RepoRoot "tools\UE4SS_Signatures"
$ReleaseReadme = Join-Path $RepoRoot "release\README.md"
$ZipPath = Join-Path $RepoRoot "SolarpunkPauseOnMenu.zip"
$StagingDir = Join-Path $env:TEMP "SolarpunkPauseOnMenu-release-$(Get-Random)"

$RequiredSignatures = @(
    "FName_Constructor.lua",
    "GUObjectArray.lua",
    "StaticConstructObject.lua"
)

if (-not (Test-Path (Join-Path $ModDir "enabled.txt"))) {
    throw "Missing SolarpunkPauseOnMenu/enabled.txt"
}
if (-not (Test-Path (Join-Path $ModDir "scripts\main.lua"))) {
    throw "Missing SolarpunkPauseOnMenu/scripts/main.lua"
}
if (-not (Test-Path $ReleaseReadme)) {
    throw "Missing release/README.md"
}
foreach ($File in $RequiredSignatures) {
    if (-not (Test-Path (Join-Path $SignaturesDir $File))) {
        throw "Missing tools/UE4SS_Signatures/$File"
    }
}

try {
    New-Item -ItemType Directory -Path $StagingDir -Force | Out-Null
    Copy-Item $ModDir (Join-Path $StagingDir "SolarpunkPauseOnMenu") -Recurse
    Copy-Item $SignaturesDir (Join-Path $StagingDir "UE4SS_Signatures") -Recurse
    Copy-Item $ReleaseReadme (Join-Path $StagingDir "README.md")

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    Compress-Archive -Path (Join-Path $StagingDir "*") -DestinationPath $ZipPath -Force
    Write-Host "Created $ZipPath"
    Write-Host "  README.md"
    Write-Host "  SolarpunkPauseOnMenu/"
    Write-Host "  UE4SS_Signatures/"
}
finally {
    if (Test-Path $StagingDir) {
        Remove-Item $StagingDir -Recurse -Force
    }
}
