# 🛡️ Orbix Sentinel - Escaneo Avanzado de Dispositivos en Red Local
# Autor: Luis Enrique Mata - Orbix AI Systems
# Versión: 2.0 - Integrado con Ae.N.K.I Dashboard

param(
    [switch]$VerboseOutput,
    [switch]$SaveReport,
    [string]$ReportPath = ".\orbix_sentinel_report.json",
    [switch]$AlertMode
)

# Configuración de colores y formato
$Host.UI.RawUI.WindowTitle = "🛡️ Orbix Sentinel - Network Scanner"

function Write-SentinelLog {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[$timestamp] ⚠️  $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[$timestamp] ❌ $Message" -ForegroundColor Red }
        "Info"    { Write-Host "[$timestamp] 🔍 $Message" -ForegroundColor Cyan }
        "Alert"   { Write-Host "[$timestamp] 🚨 $Message" -ForegroundColor Magenta }
    }
}

function Get-NetworkInterfaces {
    Write-SentinelLog "Detectando interfaces de red activas..."
    
    $interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.PrefixOrigin -eq "Dhcp" -and 
        $_.InterfaceAlias -notlike "*Loopback*" -and
        $_.IPAddress -notlike "169.254.*"
    } | Sort-Object InterfaceAlias
    
    return $interfaces
}

function Get-MacVendor {
    param($MacAddress)
    
    if (-not $MacAddress -or $MacAddress -eq "ff-ff-ff-ff-ff-ff") {
        return "Desconocido"
    }
    
    try {
        $macPrefix = $MacAddress.Substring(0, 8).ToUpper() -replace "[:-]", ""
        $url = "https://api.macvendors.com/$macPrefix"
        $vendor = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5
        return $vendor
    } catch {
        # Base de datos local de fabricantes comunes
        $vendorDB = @{
            "00:50:56" = "VMware"
            "08:00:27" = "VirtualBox"
            "52:54:00" = "QEMU/KVM"
            "00:0C:29" = "VMware"
            "00:1C:42" = "Parallels"
            "AC:DE:48" = "Private/Randomized"
            "02:00:00" = "Locally Administered"
        }
        
        $prefix = $MacAddress.Substring(0, 8).ToUpper()
        if ($vendorDB.ContainsKey($prefix)) {
            return $vendorDB[$prefix]
        }
        return "Desconocido"
    }
}

function Test-DeviceOS {
    param($IP, $Hostname)
    
    try {
        # TTL-based OS detection
        $ping = Test-Connection -ComputerName $IP -Count 1 -Quiet
        if (-not $ping) { return "Desconocido" }
        
        $ttlResult = ping -n 1 $IP | Select-String "TTL="
        if ($ttlResult) {
            $ttl = [int]($ttlResult.Line -split "TTL=" | Select-Object -Last 1).Split(' ')[0]
            
            switch ($ttl) {
                {$_ -le 64}  { $os = "Linux/Unix/Android" }
                {$_ -le 128} { $os = "Windows" }
                {$_ -le 255} { $os = "Network Device/Router" }
                default      { $os = "Desconocido" }
            }
        } else {
            $os = "Desconocido"
        }
        
        # Hostname-based detection
        if ($Hostname -like "*android*") { $os += " (Android)" }
        elseif ($Hostname -like "*iphone*" -or $Hostname -like "*ipad*") { $os += " (iOS)" }
        elseif ($Hostname -like "*samsung*") { $os += " (Samsung)" }
        elseif ($Hostname -like "*huawei*") { $os += " (Huawei)" }
        elseif ($Hostname -like "*xiaomi*") { $os += " (Xiaomi)" }
        
        return $os
    } catch {
        return "Desconocido"
    }
}

function Get-DeviceHostname {
    param($IP)
    
    try {
        $hostname = ([System.Net.Dns]::GetHostEntry($IP)).HostName
        return $hostname
    } catch {
        try {
            # Intentar con nbtstat para Windows
            $nbtResult = nbtstat -A $IP 2>$null | Select-String "^\s*\w+"
            if ($nbtResult) {
                $name = ($nbtResult[0].Line.Trim() -split '\s+')[0]
                return $name
            }
        } catch {}
        return "No detectado"
    }
}

function Test-SuspiciousDevice {
    param($Device)
    
    $suspiciousFlags = @()
    
    # Verificar MAC sospechosa
    if ($Device.MAC -eq "ff-ff-ff-ff-ff-ff") {
        $suspiciousFlags += "MAC broadcast"
    }
    
    # Verificar fabricante desconocido
    if ($Device.Vendor -eq "Desconocido") {
        $suspiciousFlags += "Fabricante desconocido"
    }
    
    # Verificar nombres sospechosos
    if ($Device.Host -like "*android*" -and $Device.Host -like "*hdpt*") {
        $suspiciousFlags += "Dispositivo Android sospechoso (HDPTAndroid)"
    }
    
    # Verificar IPs fuera del rango común
    $ipParts = $Device.IP -split '\.'
    if ($ipParts[3] -gt 200) {
        $suspiciousFlags += "IP en rango alto"
    }
    
    # Verificar dispositivos sin hostname
    if ($Device.Host -eq "No detectado") {
        $suspiciousFlags += "Sin hostname detectable"
    }
    
    return $suspiciousFlags
}

function Start-NetworkScan {
    Write-SentinelLog "🚀 Iniciando escaneo de red con Orbix Sentinel..." -Type "Info"
    
    # Detectar interfaces de red
    $interfaces = Get-NetworkInterfaces
    
    if (-not $interfaces) {
        Write-SentinelLog "No se encontraron interfaces de red válidas" -Type "Error"
        return
    }
    
    $selectedInterface = $interfaces[0]
    $ip = $selectedInterface.IPAddress
    $subnet = ($ip -replace '\d+$', '0') + "/24"
    
    Write-SentinelLog "🌐 Interface: $($selectedInterface.InterfaceAlias)" -Type "Info"
    Write-SentinelLog "🌐 IP Local: $ip" -Type "Info"
    Write-SentinelLog "🌐 Subred objetivo: $subnet" -Type "Info"
    
    # Limpiar caché ARP
    Write-SentinelLog "🧹 Limpiando caché ARP..." -Type "Info"
    arp -d * 2>$null
    
    # Escaneo activo de la red
    Write-SentinelLog "📡 Realizando ping sweep..." -Type "Info"
    $baseIP = $ip -replace '\d+$', ''
    
    $pingJobs = 1..254 | ForEach-Object {
        $targetIP = $baseIP + $_
        Start-Job -ScriptBlock {
            param($ip)
            $result = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
            if ($result) { return $ip }
        } -ArgumentList $targetIP
    }
    
    # Esperar resultados del ping
    $activeIPs = $pingJobs | Wait-Job | Receive-Job | Where-Object { $_ }
    $pingJobs | Remove-Job
    
    Write-SentinelLog "🎯 Dispositivos activos encontrados: $($activeIPs.Count)" -Type "Success"
    
    # Obtener tabla ARP actualizada
    Start-Sleep -Seconds 2
    $arpTable = arp -a | Where-Object { $_ -match "^\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s+([-\w]+)\s+dynamic" } |
        ForEach-Object {
            $parts = $_ -split "\s+"
            [PSCustomObject]@{
                IP = $parts[1]
                MAC = $parts[2]
                Host = ""
                Vendor = ""
                OS = ""
                Suspicious = @()
                LastSeen = Get-Date
            }
        }
    
    Write-SentinelLog "🔍 Analizando $($arpTable.Count) dispositivos..." -Type "Info"
    
    # Análisis detallado de cada dispositivo
    $deviceCount = 0
    foreach ($device in $arpTable) {
        $deviceCount++
        $progress = [math]::Round(($deviceCount / $arpTable.Count) * 100, 0)
        
        Write-Progress -Activity "Analizando dispositivos" -Status "Dispositivo $deviceCount de $($arpTable.Count)" -PercentComplete $progress
        
        if ($VerboseOutput) {
            Write-SentinelLog "🔍 Analizando $($device.IP)..." -Type "Info"
        }
        
        # Obtener hostname
        $device.Host = Get-DeviceHostname -IP $device.IP
        
        # Obtener fabricante
        $device.Vendor = Get-MacVendor -MacAddress $device.MAC
        
        # Detectar OS
        $device.OS = Test-DeviceOS -IP $device.IP -Hostname $device.Host
        
        # Evaluar si es sospechoso
        $device.Suspicious = Test-SuspiciousDevice -Device $device
        
        Start-Sleep -Milliseconds 100
    }
    
    Write-Progress -Completed -Activity "Analizando dispositivos"
    
    return $arpTable
}

function Show-ScanResults {
    param($Devices)
    
    Write-SentinelLog "`n📋 === REPORTE DE ESCANEO ORBIX SENTINEL ===" -Type "Success"
    Write-Host ""
    
    # Mostrar todos los dispositivos
    $Devices | Format-Table @(
        @{Name="IP Address"; Expression={$_.IP}; Width=15}
        @{Name="MAC Address"; Expression={$_.MAC}; Width=17}
        @{Name="Hostname"; Expression={$_.Host}; Width=25}
        @{Name="Vendor"; Expression={$_.Vendor}; Width=20}
        @{Name="OS Detected"; Expression={$_.OS}; Width=20}
        @{Name="Suspicious"; Expression={if($_.Suspicious.Count -gt 0){"⚠️  SÍ"}else{"✅ NO"}}; Width=10}
    ) -AutoSize
    
    # Dispositivos sospechosos
    $suspicious = $Devices | Where-Object { $_.Suspicious.Count -gt 0 }
    
    if ($suspicious.Count -gt 0) {
        Write-SentinelLog "`n🚨 ALERTA: $($suspicious.Count) dispositivo(s) sospechoso(s) detectado(s)" -Type "Alert"
        
        foreach ($device in $suspicious) {
            Write-Host "`n⚠️  Dispositivo Sospechoso:" -ForegroundColor Red
            Write-Host "   IP: $($device.IP)" -ForegroundColor Yellow
            Write-Host "   MAC: $($device.MAC)" -ForegroundColor Yellow
            Write-Host "   Hostname: $($device.Host)" -ForegroundColor Yellow
            Write-Host "   Vendor: $($device.Vendor)" -ForegroundColor Yellow
            Write-Host "   OS: $($device.OS)" -ForegroundColor Yellow
            Write-Host "   Motivos de sospecha:" -ForegroundColor Red
            foreach ($flag in $device.Suspicious) {
                Write-Host "     • $flag" -ForegroundColor Red
            }
        }
        
        if ($AlertMode) {
            # Reproducir sonido de alerta
            [System.Console]::Beep(1000, 500)
            [System.Console]::Beep(1500, 500)
            [System.Console]::Beep(1000, 500)
        }
    } else {
        Write-SentinelLog "✅ No se detectaron dispositivos sospechosos en esta exploración" -Type "Success"
    }
    
    # Estadísticas
    Write-Host "`n📊 Estadísticas del escaneo:" -ForegroundColor Cyan
    Write-Host "   Total de dispositivos: $($Devices.Count)" -ForegroundColor White
    Write-Host "   Dispositivos sospechosos: $($suspicious.Count)" -ForegroundColor White
    Write-Host "   Fabricantes conocidos: $(($Devices | Where-Object {$_.Vendor -ne 'Desconocido'}).Count)" -ForegroundColor White
    Write-Host "   Dispositivos con hostname: $(($Devices | Where-Object {$_.Host -ne 'No detectado'}).Count)" -ForegroundColor White
}

function Save-ScanReport {
    param($Devices, $FilePath)
    
    try {
        $report = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Scanner = "Orbix Sentinel v2.0"
            TotalDevices = $Devices.Count
            SuspiciousDevices = ($Devices | Where-Object { $_.Suspicious.Count -gt 0 }).Count
            Devices = $Devices
        }
        
        $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $FilePath -Encoding UTF8
        Write-SentinelLog "💾 Reporte guardado en: $FilePath" -Type "Success"
    } catch {
        Write-SentinelLog "❌ Error al guardar reporte: $($_.Exception.Message)" -Type "Error"
    }
}

# === EJECUCIÓN PRINCIPAL ===

try {
    # Banner de inicio
    Clear-Host
    Write-Host @"
🛡️  ═══════════════════════════════════════════════════════
    ___  ____  ____  _____  __  __   ___  ____  _  _ _____ ___ _  _ _____ _ 
   / _ \|  _ \| __ )|_ _\ \/ /  / _ \|  _ \| __ )(_)| |_   _|_ _| \| | ____| |
  | | | | |_) |  _ \ | | \  /  | | | | |_) |  _ \ | |   | |  | ||  \| |  _| |
  | |_| |  _ <| |_) || | /  \  | |_| |  _ <| |_) || |   | |  | || |\  | |_|_|
   \___/|_| \_\____/|___/_/\_\  \___/|_| \_\____/|_|   |_| |___|_| \_|___(_)
                                                                            
    🔍 SISTEMA DE DETECCIÓN DE AMENAZAS EN RED LOCAL
    Versión 2.0 - Integrado con Ae.N.K.I Dashboard
    Luis Enrique Mata - Orbix AI Systems
🛡️  ═══════════════════════════════════════════════════════
"@ -ForegroundColor Green

    Write-Host ""
    
    # Verificar permisos de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-SentinelLog "⚠️  Advertencia: Ejecutándose sin privilegios de administrador. Algunos datos pueden no estar disponibles." -Type "Warning"
    }
    
    # Iniciar escaneo
    $startTime = Get-Date
    $devices = Start-NetworkScan
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    if ($devices) {
        Show-ScanResults -Devices $devices
        
        if ($SaveReport) {
            Save-ScanReport -Devices $devices -FilePath $ReportPath
        }
        
        Write-SentinelLog "`n⏱️  Escaneo completado en $([math]::Round($duration.TotalSeconds, 2)) segundos" -Type "Success"
    } else {
        Write-SentinelLog "❌ No se pudieron obtener resultados del escaneo" -Type "Error"
    }
    
} catch {
    Write-SentinelLog "❌ Error crítico durante el escaneo: $($_.Exception.Message)" -Type "Error"
    Write-SentinelLog "📍 Línea: $($_.InvocationInfo.ScriptLineNumber)" -Type "Error"
} finally {
    Write-SentinelLog "`n🔚 Orbix Sentinel finalizado. Manteniendo vigilancia..." -Type "Info"
    
    # Mantener la ventana abierta si se ejecuta directamente
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "`nPresiona cualquier tecla para continuar..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
