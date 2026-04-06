# ========================================================
# Catyami Otimizacao - Painel de Monitoramento
# ========================================================
# Execute no PowerShell como Administrador
# ========================================================

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "    CATYAMI OTIMIZACAO - PAINEL DE MONITORAMENTO"       -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# CPU
$cpu = Get-CimInstance Win32_Processor
$cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Sum).Sum
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor Green
Write-Host "  Cores: $($cpu.NumberOfCores) | Threads: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor Green
Write-Host "  Clock Atual: $($cpu.CurrentClockSpeed) MHz" -ForegroundColor Green
Write-Host ""

# RAM
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
$pctUsed = [math]::Round(($usedGB / $totalGB) * 100, 1)
Write-Host "  RAM: ${usedGB}GB / ${totalGB}GB (livre: ${freeGB}GB) - ${pctUsed}%" -ForegroundColor Yellow
Write-Host ""

# GPU
Write-Host "  GPUs:" -ForegroundColor Magenta
$gpus = Get-CimInstance Win32_VideoController
$gpus | ForEach-Object {
    $vram = if ($_.AdapterRAM -gt 0 -and $_.AdapterRAM -lt 10000000000) {
        [math]::Round($_.AdapterRAM / 1MB, 0)
    } elseif ($_.AdapterRAM -ge 10000000000) {
        [math]::Round($_.AdapterRAM / 1GB, 1)
    } else {
        "N/A"
    }
    Write-Host "    $($_.Name)" -ForegroundColor Magenta
    Write-Host "    VRAM: ${vram} GB | Driver: $($_.DriverVersion)" -ForegroundColor Magenta
    Write-Host ""
}

# Disco
Write-Host "  Discos:" -ForegroundColor Red
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $size = [math]::Round($_.Size / 1GB, 1)
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $used = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 1)
    Write-Host "    $($_.DeviceID) [ $($_.VolumeName) ]" -ForegroundColor Red
    Write-Host "    ${free}GB livres de ${size}GB (usado: ${used}GB)" -ForegroundColor Red
    Write-Host ""
}

# Network / Ping
Write-Host "  Teste de Ping (1.1.1.1):" -ForegroundColor White
try {
    $ping = Test-Connection -ComputerName 1.1.1.1 -Count 4 -ErrorAction Stop | Measure-Object -Property ResponseTime -Average
    Write-Host "    Ping Medio: $([math]::Round($ping.Average, 1))ms" -ForegroundColor White
} catch {
    Write-Host "    Nao foi possivel testar o ping" -ForegroundColor DarkGray
}
Write-Host ""

# Uptime
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$days = $uptime.Days
$hours = $uptime.Hours
$mins = $uptime.Minutes
Write-Host "  Uptime: $days dias, $hours horas, $mins minutos" -ForegroundColor White
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Pressione qualquer tecla para sair..."                -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
