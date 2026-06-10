param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Release", "Dev")]
    [string]$Mode,

    [switch]$UpdateGit
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ConfigFile = Join-Path $RepoRoot "config\game-path.local"
$ExampleFile = Join-Path $RepoRoot "config\game-path.local.example"
$ModeFile = Join-Path $RepoRoot "config\console-mode.txt"

if (-not (Test-Path $ConfigFile)) {
    if (Test-Path $ExampleFile) {
        Copy-Item $ExampleFile $ConfigFile
        Write-Host "Created config/game-path.local from example."
    }
    else {
        throw "Missing config/game-path.local. Copy config/game-path.local.example and set your UE4SS-settings.ini path."
    }
}

$SettingsPath = (Get-Content $ConfigFile -Raw).Trim()
if (-not (Test-Path $SettingsPath)) {
    throw "UE4SS-settings.ini not found: $SettingsPath"
}

$Values = if ($Mode -eq "Release") {
    @{
        ConsoleEnabled    = 0
        GuiConsoleEnabled = 0
        GuiConsoleVisible = 0
    }
}
else {
    @{
        ConsoleEnabled    = 1
        GuiConsoleEnabled = 1
        GuiConsoleVisible = 1
    }
}

$Content = Get-Content $SettingsPath -Raw
foreach ($Key in $Values.Keys) {
    $Pattern = "($Key\s*=\s*)\d+"
    if ($Content -notmatch $Pattern) {
        throw "Setting not found in UE4SS-settings.ini: $Key"
    }
    $Content = [regex]::Replace($Content, $Pattern, "`${1}$($Values[$Key])", 1)
}

Set-Content -Path $SettingsPath -Value $Content -NoNewline -Encoding UTF8
Set-Content -Path $ModeFile -Value $Mode.ToLower() -NoNewline -Encoding UTF8

Write-Host "UE4SS console: $Mode mode -> $SettingsPath"

if ($UpdateGit) {
    Push-Location $RepoRoot
    try {
        git add config/console-mode.txt | Out-Null
        $Status = git status --porcelain config/console-mode.txt
        if ($Status) {
            git commit -m "chore: disable UE4SS debug consoles for release" | Out-Null
            Write-Host "Committed config/console-mode.txt (release)."
        }
    }
    finally {
        Pop-Location
    }
}
