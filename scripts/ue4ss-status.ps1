$win64 = "E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64"
$log = Join-Path $win64 "ue4ss\UE4SS.log"

if (Test-Path (Join-Path $win64 "dwmapi.dll")) {
    Write-Host "UE4SS: ATIVO (dwmapi.dll presente)"
} elseif (Test-Path (Join-Path $win64 "dwmapi.dll.off")) {
    Write-Host "UE4SS: DESATIVADO (dwmapi.dll.off)"
} else {
    Write-Host "UE4SS: NAO INSTALADO"
}

if (Test-Path $log) {
    $info = Get-Item $log
    Write-Host "Log: $($info.LastWriteTime) | $([math]::Round($info.Length/1KB)) KB"
    Write-Host "--- Ultimas 8 linhas ---"
    Get-Content $log -Tail 8
} else {
    Write-Host "Log: nao encontrado (jogo ainda nao abriu com UE4SS)"
}
