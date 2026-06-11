$win64 = "E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64"
$dll = Join-Path $win64 "dwmapi.dll"
$off = Join-Path $win64 "dwmapi.dll.off"

if (Test-Path $dll) {
    Write-Host "UE4SS ja esta ativo (dwmapi.dll existe)."
    exit 0
}

if (-not (Test-Path $off)) {
    Write-Error "Nao encontrei dwmapi.dll.off em $win64"
    exit 1
}

Rename-Item $off "dwmapi.dll"
Write-Host "UE4SS reativado. Abra o jogo pela Steam."
