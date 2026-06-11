$win64 = "E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64"
$dll = Join-Path $win64 "dwmapi.dll"
$off = Join-Path $win64 "dwmapi.dll.off"

if (Test-Path $off) {
    Write-Host "UE4SS ja esta desativado (dwmapi.dll.off existe)."
    exit 0
}

if (-not (Test-Path $dll)) {
    Write-Error "Nao encontrei dwmapi.dll em $win64"
    exit 1
}

Rename-Item $dll "dwmapi.dll.off"
Write-Host "UE4SS desativado. O jogo abre sem mods."
