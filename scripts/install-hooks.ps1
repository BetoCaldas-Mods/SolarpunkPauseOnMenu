$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$GitHooksDir = Join-Path $RepoRoot ".git\hooks"

if (-not (Test-Path $GitHooksDir)) {
    throw "Not a git repository: $RepoHooksDir"
}

$Hooks = @("pre-push", "post-checkout")
foreach ($Hook in $Hooks) {
    $Source = Join-Path $RepoRoot "scripts\hooks\$Hook"
    $Target = Join-Path $GitHooksDir $Hook
    Copy-Item $Source $Target -Force
    Write-Host "Installed $Hook"
}

$ExamplePath = Join-Path $RepoRoot "config\game-path.local.example"
$LocalPath = Join-Path $RepoRoot "config\game-path.local"
if (-not (Test-Path $LocalPath) -and (Test-Path $ExamplePath)) {
    Copy-Item $ExamplePath $LocalPath
    Write-Host "Created config/game-path.local from example."
}

Write-Host "Git hooks installed. Run scripts/dev-start.ps1 to enable debug consoles now."
