# =============================================================================
# Orbix Sentinel - Advanced Network Security Scanner
# Autor: Luis Enrique Mata - Orbix AI Systems
# Version: 3.0 - Enhanced Threat Detection
# =============================================================================

param(
    [string]$Interface = "Auto",
    [switch]$DetailedScan,
    [switch]$Silent,
    [string]$OutputFormat = "Console", # Console, JSON, CSV, XML
    [string]$OutputFile = "",
    [switch]$AlertMode,
    [switch]$ContinuousMode,
    [int]$ScanInterval = 300, # 5 minutos
    [switch]$PortScan,
    [switch]$VulnerabilityCheck
)

# Configuración avanzada
$script:Config = @{
    Colors = @{
        Header = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
        Info = "White"
        Suspicious = "Magenta"
        Critical = "DarkRed"
    }
    ThreatLevels = @{
        Normal = 0
        Low = 1
        Medium = 2
        High = 3
        Critical = 4
    }
    SuspiciousPatterns = @(
        "hdptandroid",
        "unknown",
        "android-[a-f0-9]{8}",
        "^[a-f0-9-]{17}$",
        "test-device",
        "hacker",
        "exploit"
    )
    CommonPorts = @(21, 22, 23, 25, 53, 80, 110, 143, 443, 993, 995, 1433, 3306, 3389, 5432, 5900, 8080, 8443)
}

# Banner avanzado
if (-not $Silent) {
    Clear-Host
    Write-Host @"
    
╔══════════════════════════════════════════════════════════════════════════════╗
║                        🛡️  ORBIX SENTINEL v3.0                             ║
║                   Advanced Network Security Scanner                         ║
║                      Powered by Ae.N.K.I Intelligence                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
║  🔍 Network Discovery    🚨 Threat Detection    📊 Vulnerability Assessment ║
║  🎯 Advanced Profiling   📡 Port Scanning      🔒 Security Monitoring      ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor $script:Config.Colors.Header
}

# Clase para dispositivos de red
class NetworkDevice {
    [string]$IP
    [string]$MAC
    [string]$Hostname
    [string]$Vendor
    [string]$OS
    [string]$DeviceType
    [int]$ThreatLevel
    [string]$ThreatDescription
    [array]$OpenPorts
    [array]$Vulnerabilities
    [array]$SuspiciousReasons
    [datetime]$FirstSeen
    [datetime]$LastSeen
    [int]$ScanCount
    [hashtable]$AdditionalInfo
    
    NetworkDevice() {
        $this.OpenPorts = @()
        $this.Vulnerabilities = @()
        $this.SuspiciousReasons = @()
        $this.FirstSeen = Get-Date
        $this.LastSeen = Get-Date
        $this.ScanCount = 1
        $this.AdditionalInfo = @{}
        $this.ThreatLevel = 0
    }
    
    [void]UpdateLastSeen() {
        $this.LastSeen = Get-Date
        $this.ScanCount++
    }
    
    [string]GetThreatLevelName() {
        switch ($this.ThreatLevel) {
            0 { return "Normal" }
            1 { return "Bajo" }
            2 { return "Medio" }
            3 { return "Alto" }
            4 { return "Crítico" }
            default { return "Desconocido" }
        }
    }
    
    [string]GetRiskColor() {
        switch ($this.ThreatLevel) {
            0 { return "Green" }
            1 { return "Yellow" }
            2 { return "DarkYellow" }
            3 { return "Red" }
            4 { return "DarkRed" }
            default { return "Gray" }
        }
        return "Gray"
    }
}

# Función de logging avanzada
function Write-SentinelLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White",
        [switch]$NoTimestamp
    )
    
    if ($Silent) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    
    if ($NoTimestamp) {
        $logMessage = $Message
    } else {
        $logMessage = "[$timestamp] [$Level] $Message"
    }
    
    Write-Host $logMessage -ForegroundColor $Color
    
    # Log a archivo si está especificado
    if ($OutputFile) {
        $logPath = $OutputFile.Replace('.json', '.log').Replace('.csv', '.log').Replace('.xml', '.log')
        Add-Content -Path $logPath -Value $logMessage -ErrorAction SilentlyContinue
    }
}

# Función para detectar sistema operativo avanzado
function Get-AdvancedOS {
    param(
        [string]$MAC,
        [string]$Vendor,
        [string]$Hostname,
        [array]$OpenPorts,
        [string]$IP
    )
    
    $os = "Desconocido"
    $confidence = 0
    
    # Detección por vendor (alta confianza)
    if ($Vendor -match "Apple") { $os = "iOS/macOS"; $confidence = 80 }
    elseif ($Vendor -match "Samsung") { $os = "Android/Tizen"; $confidence = 75 }
    elseif ($Vendor -match "Microsoft") { $os = "Windows"; $confidence = 85 }
    elseif ($Vendor -match "Google") { $os = "Android"; $confidence = 80 }
    elseif ($Vendor -match "Raspberry") { $os = "Linux (Raspberry Pi)"; $confidence = 90 }
    elseif ($Vendor -match "Intel") { $os = "Windows/Linux"; $confidence = 40 }
    elseif ($Vendor -match "Qualcomm|Broadcom") { $os = "Android/Linux"; $confidence = 60 }
    elseif ($Vendor -match "Xiaomi|Huawei|OnePlus") { $os = "Android"; $confidence = 85 }
    
    # Detección por hostname (media confianza)
    if ($Hostname -match "android|droid" -and $confidence -lt 70) { $os = "Android"; $confidence = 70 }
    elseif ($Hostname -match "iphone|ipad|mac" -and $confidence -lt 70) { $os = "iOS/macOS"; $confidence = 70 }
    elseif ($Hostname -match "windows|win|pc" -and $confidence -lt 70) { $os = "Windows"; $confidence = 70 }
    elseif ($Hostname -match "linux|ubuntu|debian" -and $confidence -lt 70) { $os = "Linux"; $confidence = 70 }
    elseif ($Hostname -match "router|gateway|ap" -and $confidence -lt 70) { $os = "Router/Gateway"; $confidence = 80 }
    
    # Detección por puertos abiertos (baja confianza)
    if ($OpenPorts -contains 3389 -and $confidence -lt 50) { $os = "Windows (RDP)"; $confidence = 50 }
    elseif ($OpenPorts -contains 22 -and $confidence -lt 50) { $os = "Linux/Unix (SSH)"; $confidence = 50 }
    elseif ($OpenPorts -contains 5900 -and $confidence -lt 50) { $os = "macOS/Linux (VNC)"; $confidence = 50 }
    
    return @{
        OS = $os
        Confidence = $confidence
    }
}

# Función para detectar tipo de dispositivo
function Get-DeviceType {
    param(
        [string]$MAC,
        [string]$Vendor,
        [string]$Hostname,
        [string]$OS,
        [array]$OpenPorts
    )
    
    # Routers y puntos de acceso
    if ($Hostname -match "router|gateway|ap|wifi" -or $OpenPorts -contains 80 -and $OpenPorts -contains 443) {
        return "Router/Gateway"
    }
    
    # Servidores
    if ($OpenPorts -contains 22 -or $OpenPorts -contains 3389 -or $OpenPorts -contains 1433 -or $OpenPorts -contains 3306) {
        return "Servidor"
    }
    
    # Dispositivos móviles
    if ($OS -match "Android|iOS" -or $Vendor -match "Samsung|Apple|Google|Xiaomi|Huawei|OnePlus") {
        return "Dispositivo Móvil"
    }
    
    # Computadoras
    if ($OS -match "Windows|macOS|Linux" -and $OS -notmatch "Android|iOS") {
        return "Computadora"
    }
    
    # IoT/Embebidos
    if ($Vendor -match "Raspberry|Arduino|ESP" -or $Hostname -match "iot|sensor|cam") {
        return "IoT/Embebido"
    }
    
    # Impresoras
    if ($OpenPorts -contains 9100 -or $OpenPorts -contains 631) {
        return "Impresora"
    }
    
    return "Desconocido"
}

# Función para escaneo de puertos
function Start-PortScan {
    param(
        [string]$IP,
        [array]$Ports = $script:Config.CommonPorts
    )
    
    $openPorts = @()
    
    foreach ($port in $Ports) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connection = $tcpClient.BeginConnect($IP, $port, $null, $null)
            $wait = $connection.AsyncWaitHandle.WaitOne(1000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connection)
                $openPorts += $port
            }
            
            $tcpClient.Close()
        } catch {
            # Puerto cerrado o filtrado
        }
    }
    
    return $openPorts
}

# Función para evaluación de amenazas avanzada
function Get-ThreatAssessment {
    param(
        [NetworkDevice]$Device
    )
    
    $threatScore = 0
    $reasons = @()
    
    # Evaluación por hostname
    foreach ($pattern in $script:Config.SuspiciousPatterns) {
        if ($Device.Hostname -match $pattern) {
            $threatScore += 25
            $reasons += "Hostname sospechoso: $pattern"
        }
    }
    
    # Evaluación por vendor
    if ($Device.Vendor -eq "Desconocido" -or $Device.Vendor -eq "Unknown") {
        $threatScore += 20
        $reasons += "Fabricante desconocido"
    }
    
    # Evaluación por MAC
    if ($Device.MAC -match "^(00:00:00|ff:ff:ff|02:00:00)") {
        $threatScore += 30
        $reasons += "MAC address sospechosa"
    }
    
    # Evaluación por puertos abiertos
    $dangerousPorts = @(23, 21, 1433, 3306, 5432) # Telnet, FTP, SQL Server, MySQL, PostgreSQL
    foreach ($port in $Device.OpenPorts) {
        if ($port -in $dangerousPorts) {
            $threatScore += 15
            $reasons += "Puerto peligroso abierto: $port"
        }
    }
    
    # Evaluación por primera aparición
    if ($Device.ScanCount -eq 1 -and $Device.FirstSeen -gt (Get-Date).AddMinutes(-10)) {
        $threatScore += 10
        $reasons += "Dispositivo nuevo en la red"
    }
    
    # Evaluación por combinación sospechosa
    if ($Device.OS -match "Android" -and $Device.Hostname -notmatch "samsung|google|xiaomi|huawei|oneplus") {
        $threatScore += 15
        $reasons += "Android con hostname no estándar"
    }
    
    # Determinar nivel de amenaza
    $threatLevel = 0
    if ($threatScore -ge 80) { $threatLevel = 4 }      # Crítico
    elseif ($threatScore -ge 60) { $threatLevel = 3 }  # Alto
    elseif ($threatScore -ge 40) { $threatLevel = 2 }  # Medio
    elseif ($threatScore -ge 20) { $threatLevel = 1 }  # Bajo
    
    $Device.ThreatLevel = $threatLevel
    $Device.SuspiciousReasons = $reasons
    $Device.ThreatDescription = "Puntuación: $threatScore/100"
    
    return $Device
}

# Función principal de escaneo
function Start-NetworkDiscovery {
    Write-SentinelLog "Iniciando descubrimiento de red avanzado..." "SCAN" $script:Config.Colors.Info
    
    # Detectar interfaces de red
    $interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.PrefixOrigin -eq "Dhcp" -and $_.IPAddress -notmatch "^127\." 
    }
    
    $activeInterface = if ($Interface -eq "Auto") { 
        $interfaces | Select-Object -First 1 
    } else { 
        $interfaces | Where-Object { $_.InterfaceAlias -eq $Interface } 
    }
    
    if (-not $activeInterface) {
        Write-SentinelLog "No se encontró interfaz de red activa" "ERROR" $script:Config.Colors.Error
        return @()
    }
    
    $localIP = $activeInterface.IPAddress
    $networkBase = $localIP.Substring(0, $localIP.LastIndexOf('.'))
    
    Write-SentinelLog "Interface: $($activeInterface.InterfaceAlias)" "INFO" $script:Config.Colors.Info
    Write-SentinelLog "IP Local: $localIP" "INFO" $script:Config.Colors.Info
    Write-SentinelLog "Red objetivo: $networkBase.0/24" "INFO" $script:Config.Colors.Info
    
    # Ping sweep paralelo
    Write-SentinelLog "Realizando ping sweep..." "SCAN" $script:Config.Colors.Info
    
    $pingJobs = @()
    1..254 | ForEach-Object {
        $targetIP = "$networkBase.$_"
        $pingJobs += Start-Job -ScriptBlock {
            param($ip)
            if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSec 1) {
                return $ip
            }
        } -ArgumentList $targetIP
    }
    
    # Recopilar resultados
    $activeIPs = @()
    $pingJobs | ForEach-Object {
        $result = Wait-Job $_ -Timeout 5 | Receive-Job
        if ($result) { $activeIPs += $result }
        Remove-Job $_
    }
    
    Write-SentinelLog "Dispositivos activos: $($activeIPs.Count)" "SUCCESS" $script:Config.Colors.Success
    
    # Obtener información ARP
    $arpTable = @{}
    arp -a | Where-Object { $_ -match "^\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s+([-\w]+)\s+" } | ForEach-Object {
        $parts = $_ -split "\s+"
        $arpTable[$parts[1]] = $parts[2]
    }
    
    # Procesar cada dispositivo
    $devices = @()
    $counter = 0
    
    foreach ($ip in $activeIPs) {
        $counter++
        $progress = [math]::Round(($counter / $activeIPs.Count) * 100, 1)
        Write-SentinelLog "Analizando dispositivo $counter/$($activeIPs.Count) ($progress%): $ip" "SCAN" $script:Config.Colors.Info
        
        $device = [NetworkDevice]::new()
        $device.IP = $ip
        
        # Obtener MAC de la tabla ARP
        if ($arpTable.ContainsKey($ip)) {
            $device.MAC = $arpTable[$ip]
        } else {
            $device.MAC = "No detectado"
        }
        
        # Resolver hostname
        try {
            $device.Hostname = ([System.Net.Dns]::GetHostEntry($ip)).HostName
        } catch {
            $device.Hostname = "No resuelto"
        }
        
        # Obtener fabricante
        if ($device.MAC -ne "No detectado") {
            $device.Vendor = Get-MACVendor -MAC $device.MAC
        } else {
            $device.Vendor = "Desconocido"
        }
        
        # Escaneo de puertos si está habilitado
        if ($PortScan) {
            $device.OpenPorts = Start-PortScan -IP $ip
        }
        
        # Detectar sistema operativo
        $osInfo = Get-AdvancedOS -MAC $device.MAC -Vendor $device.Vendor -Hostname $device.Hostname -OpenPorts $device.OpenPorts -IP $ip
        $device.OS = $osInfo.OS
        $device.AdditionalInfo["OSConfidence"] = $osInfo.Confidence
        
        # Detectar tipo de dispositivo
        $device.DeviceType = Get-DeviceType -MAC $device.MAC -Vendor $device.Vendor -Hostname $device.Hostname -OS $device.OS -OpenPorts $device.OpenPorts
        
        # Evaluación de amenazas
        $device = Get-ThreatAssessment -Device $device
        
        $devices += $device
    }
    
    return $devices
}

# Función para obtener información del fabricante
function Get-MACVendor {
    param([string]$MAC)
    
    if (-not $MAC -or $MAC -eq "No detectado") {
        return "Desconocido"
    }
    
    try {
        $macPrefix = $MAC.Substring(0, 8).ToUpper() -replace "[:-]", ""
        $url = "https://api.macvendors.com/$macPrefix"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 3
        return $response
    } catch {
        # Base de datos local extendida
        $localVendors = @{
            "00:1B:63" = "Apple"
            "00:23:12" = "Samsung"
            "00:26:BB" = "Microsoft"
            "B8:27:EB" = "Raspberry Pi Foundation"
            "DC:A6:32" = "Raspberry Pi Foundation"
            "E4:5F:01" = "Raspberry Pi Foundation"
            "00:15:5D" = "Microsoft (Hyper-V)"
            "08:00:27" = "Oracle VirtualBox"
            "00:0C:29" = "VMware"
            "00:50:56" = "VMware"
            "52:54:00" = "QEMU/KVM"
            "00:16:3E" = "Xen"
            "00:1C:42" = "Parallels"
            "AC:DE:48" = "Intel"
            "00:90:7F" = "Linksys"
            "00:1D:7E" = "Netgear"
            "00:24:01" = "D-Link"
        }
        
        $macPrefix = $MAC.Substring(0, 8).ToUpper()
        if ($localVendors.ContainsKey($macPrefix)) {
            return $localVendors[$macPrefix]
        }
        return "Desconocido"
    }
}

# Función para mostrar resultados detallados
function Show-DetailedResults {
    param([array]$Devices)
    
    if ($Devices.Count -eq 0) {
        Write-SentinelLog "No se encontraron dispositivos" "WARNING" $script:Config.Colors.Warning
        return
    }
    
    $totalDevices = $Devices.Count
    $threatDevices = $Devices | Where-Object { $_.ThreatLevel -gt 0 }
    $criticalDevices = $Devices | Where-Object { $_.ThreatLevel -eq 4 }
    $highThreatDevices = $Devices | Where-Object { $_.ThreatLevel -eq 3 }
    
    Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "                           📊 RESUMEN DE ANÁLISIS DE RED                        " "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
    
    Write-SentinelLog "📱 Total de dispositivos descubiertos: $totalDevices" "INFO" $script:Config.Colors.Success
    Write-SentinelLog "⚠️  Dispositivos con amenazas: $($threatDevices.Count)" "INFO" $script:Config.Colors.Warning
    Write-SentinelLog "🔴 Amenazas de nivel alto: $($highThreatDevices.Count)" "INFO" $script:Config.Colors.Error
    Write-SentinelLog "🚨 Amenazas críticas: $($criticalDevices.Count)" "INFO" $script:Config.Colors.Critical
    
    Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "                              📋 INVENTARIO DE DISPOSITIVOS                     " "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
    
    # Mostrar dispositivos ordenados por nivel de amenaza
    $sortedDevices = $Devices | Sort-Object ThreatLevel -Descending
    
    foreach ($device in $sortedDevices) {
        $color = $device.GetRiskColor()
        $threatName = $device.GetThreatLevelName()
        $confidenceInfo = if ($device.AdditionalInfo.ContainsKey("OSConfidence")) { 
            " (Confianza: $($device.AdditionalInfo.OSConfidence)%)" 
        } else { "" }
        
        Write-Host ""
        Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor $color
        Write-Host "│ IP: $($device.IP.PadRight(15)) │ Amenaza: $($threatName.PadRight(8)) │ Tipo: $($device.DeviceType.PadRight(15)) │" -ForegroundColor $color
        Write-Host "│ MAC: $($device.MAC.PadRight(17)) │ Vendor: $($device.Vendor.PadRight(20)) │" -ForegroundColor $color
        Write-Host "│ Host: $($device.Hostname.PadRight(35)) │ OS: $($device.OS + $confidenceInfo)" -ForegroundColor $color
        
        if ($device.OpenPorts.Count -gt 0) {
            $portsStr = ($device.OpenPorts | Sort-Object) -join ", "
            Write-Host "│ Puertos abiertos: $portsStr" -ForegroundColor $color
        }
        
        if ($device.SuspiciousReasons.Count -gt 0) {
            Write-Host "│ Razones de alerta:" -ForegroundColor $color
            foreach ($reason in $device.SuspiciousReasons) {
                Write-Host "│   • $reason" -ForegroundColor $color
            }
        }
        
        Write-Host "│ Primera detección: $($device.FirstSeen.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $color
        Write-Host "│ Última detección: $($device.LastSeen.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $color
        Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor $color
    }
    
    # Alertas especiales
    if ($threatDevices.Count -gt 0) {
        Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
        Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "ALERT" $script:Config.Colors.Error -NoTimestamp
        Write-SentinelLog "                              🚨 ALERTAS DE SEGURIDAD                          " "ALERT" $script:Config.Colors.Error -NoTimestamp
        Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "ALERT" $script:Config.Colors.Error -NoTimestamp
        
        foreach ($device in $threatDevices) {
            $threatName = $device.GetThreatLevelName()
            Write-SentinelLog "🎯 $($device.IP) - $($device.Hostname) - Nivel: $threatName" "ALERT" $script:Config.Colors.Error
            Write-SentinelLog "   Descripción: $($device.ThreatDescription)" "ALERT" $script:Config.Colors.Warning
        }
        
        # Buscar específicamente HDPTAndroid y patrones sospechosos
        $hdptDevices = $Devices | Where-Object { $_.Hostname -match "hdptandroid" }
        if ($hdptDevices.Count -gt 0) {
            Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
            Write-SentinelLog "🎯 DISPOSITIVOS HDPTANDROID DETECTADOS:" "CRITICAL" $script:Config.Colors.Critical
            Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "CRITICAL" $script:Config.Colors.Critical -NoTimestamp
            
            foreach ($device in $hdptDevices) {
                Write-SentinelLog "🚨 ALERTA CRÍTICA: Dispositivo HDPTAndroid detectado" "CRITICAL" $script:Config.Colors.Critical
                Write-SentinelLog "   IP: $($device.IP) | MAC: $($device.MAC)" "CRITICAL" $script:Config.Colors.Critical
                Write-SentinelLog "   Hostname: $($device.Hostname)" "CRITICAL" $script:Config.Colors.Critical
                Write-SentinelLog "   Vendor: $($device.Vendor) | OS: $($device.OS)" "CRITICAL" $script:Config.Colors.Critical
                Write-SentinelLog "   Nivel de amenaza: $($device.GetThreatLevelName())" "CRITICAL" $script:Config.Colors.Critical
                
                if ($device.OpenPorts.Count -gt 0) {
                    Write-SentinelLog "   Puertos abiertos: $($device.OpenPorts -join ', ')" "CRITICAL" $script:Config.Colors.Critical
                }
            }
        }
    }
    
    Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "                           ✅ ESCANEO COMPLETADO                               " "INFO" $script:Config.Colors.Header -NoTimestamp
    Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
}

# Función para exportar resultados
function Export-ScanResults {
    param(
        [array]$Devices,
        [string]$Format,
        [string]$FilePath
    )
    
    if (-not $FilePath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $FilePath = "orbix_sentinel_scan_$timestamp"
    }
    
    try {
        switch ($Format.ToLower()) {
            "json" {
                $exportData = @{
                    ScanTimestamp = Get-Date
                    TotalDevices = $Devices.Count
                    ThreatDevices = ($Devices | Where-Object { $_.ThreatLevel -gt 0 }).Count
                    Devices = $Devices
                }
                $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath "$FilePath.json" -Encoding UTF8
                Write-SentinelLog "Resultados exportados: $FilePath.json" "SUCCESS" $script:Config.Colors.Success
            }
            "csv" {
                $Devices | Select-Object IP, MAC, Hostname, Vendor, OS, DeviceType, 
                    @{Name="ThreatLevel"; Expression={$_.GetThreatLevelName()}}, 
                    ThreatDescription, 
                    @{Name="OpenPorts"; Expression={$_.OpenPorts -join "; "}}, 
                    @{Name="SuspiciousReasons"; Expression={$_.SuspiciousReasons -join "; "}}, 
                    FirstSeen, LastSeen, ScanCount | 
                    Export-Csv -Path "$FilePath.csv" -NoTypeInformation -Encoding UTF8
                Write-SentinelLog "Resultados exportados: $FilePath.csv" "SUCCESS" $script:Config.Colors.Success
            }
            "xml" {
                $Devices | Export-Clixml -Path "$FilePath.xml"
                Write-SentinelLog "Resultados exportados: $FilePath.xml" "SUCCESS" $script:Config.Colors.Success
            }
        }
    } catch {
        Write-SentinelLog "Error al exportar: $($_.Exception.Message)" "ERROR" $script:Config.Colors.Error
    }
}

# Función para alertas
function Send-ThreatAlert {
    param([array]$ThreatDevices)
    
    if ($ThreatDevices.Count -eq 0) { return }
    
    # Alerta sonora
    try {
        for ($i = 0; $i -lt 3; $i++) {
            [Console]::Beep(1000, 300)
            Start-Sleep -Milliseconds 200
            [Console]::Beep(800, 300)
            Start-Sleep -Milliseconds 200
        }
    } catch {
        Write-SentinelLog "No se pudo reproducir alerta sonora" "WARNING" $script:Config.Colors.Warning
    }
    
    # Aquí puedes integrar con servicios externos:
    # - Telegram Bot
    # - Email notifications
    # - SIEM systems
    # - Discord webhooks
    # - Slack notifications
}

# Función para modo continuo
function Start-ContinuousMonitoring {
    Write-SentinelLog "Iniciando monitoreo continuo (intervalo: $ScanInterval segundos)" "INFO" $script:Config.Colors.Info
    
    $deviceHistory = @{}
    $scanCount = 0
    
    while ($true) {
        $scanCount++
        Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
        Write-SentinelLog "                         ESCANEO CONTINUO #$scanCount                         " "INFO" $script:Config.Colors.Header -NoTimestamp
        Write-SentinelLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $script:Config.Colors.Header -NoTimestamp
        
        $devices = Start-NetworkDiscovery
        
        # Comparar con escaneos anteriores
        $newDevices = @()
        $lostDevices = @()
        
        foreach ($device in $devices) {
            if (-not $deviceHistory.ContainsKey($device.IP)) {
                $newDevices += $device
                $deviceHistory[$device.IP] = $device
            } else {
                $deviceHistory[$device.IP].UpdateLastSeen()
            }
        }
        
        # Detectar dispositivos que ya no están
        $currentIPs = $devices | ForEach-Object { $_.IP }
        foreach ($ip in $deviceHistory.Keys) {
            if ($ip -notin $currentIPs -and $deviceHistory[$ip].LastSeen -lt (Get-Date).AddMinutes(-10)) {
                $lostDevices += $deviceHistory[$ip]
            }
        }
        
        # Mostrar resultados
        Show-DetailedResults -Devices $devices
        
        # Alertas para nuevos dispositivos
        if ($newDevices.Count -gt 0) {
            Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
            Write-SentinelLog "🆕 NUEVOS DISPOSITIVOS DETECTADOS:" "ALERT" $script:Config.Colors.Warning
            foreach ($device in $newDevices) {
                Write-SentinelLog "   → $($device.IP) - $($device.Hostname)" "ALERT" $script:Config.Colors.Warning
            }
        }
        
        # Alertas para dispositivos perdidos
        if ($lostDevices.Count -gt 0) {
            Write-SentinelLog "" "INFO" $script:Config.Colors.Info -NoTimestamp
            Write-SentinelLog "📴 DISPOSITIVOS DESCONECTADOS:" "ALERT" $script:Config.Colors.Info
            foreach ($device in $lostDevices) {
                Write-SentinelLog "   → $($device.IP) - $($device.Hostname)" "ALERT" $script:Config.Colors.Info
            }
        }
        
        # Exportar si se especifica
        if ($OutputFormat -ne "Console") {
            Export-ScanResults -Devices $devices -Format $OutputFormat -FilePath $OutputFile
        }
        
        # Alertas para amenazas
        $threatDevices = $devices | Where-Object { $_.ThreatLevel -gt 0 }
        if ($AlertMode -and $threatDevices.Count -gt 0) {
            Send-ThreatAlert -ThreatDevices $threatDevices
        }
        
        Write-SentinelLog "Próximo escaneo en $ScanInterval segundos..." "INFO" $script:Config.Colors.Info
        Start-Sleep -Seconds $ScanInterval
    }
}

# EJECUCIÓN PRINCIPAL
try {
    # Verificar permisos
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-SentinelLog "⚠️  Se recomienda ejecutar como administrador para mejores resultados" "WARNING" $script:Config.Colors.Warning
    }
    
    # Verificar conectividad
    if (-not (Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet)) {
        Write-SentinelLog "⚠️  Sin conexión a Internet. Algunas funciones pueden estar limitadas." "WARNING" $script:Config.Colors.Warning
    }
    
    if ($ContinuousMode) {
        Start-ContinuousMonitoring
    } else {
        # Escaneo único
        $devices = Start-NetworkDiscovery
        
        if ($devices.Count -eq 0) {
            Write-SentinelLog "No se detectaron dispositivos en la red" "ERROR" $script:Config.Colors.Error
            exit 1
        }
        
        # Mostrar resultados
        Show-DetailedResults -Devices $devices
        
        # Exportar resultados
        if ($OutputFormat -ne "Console") {
            Export-ScanResults -Devices $devices -Format $OutputFormat -FilePath $OutputFile
        }
        
        # Alertas
        $threatDevices = $devices | Where-Object { $_.ThreatLevel -gt 0 }
        if ($AlertMode -and $threatDevices.Count -gt 0) {
            Send-ThreatAlert -ThreatDevices $threatDevices
        }
        
        # Código de salida
        if ($devices | Where-Object { $_.ThreatLevel -eq 4 }) {
            exit 4  # Amenaza crítica
        } elseif ($devices | Where-Object { $_.ThreatLevel -eq 3 }) {
            exit 3  # Amenaza alta
        } elseif ($devices | Where-Object { $_.ThreatLevel -eq 2 }) {
            exit 2  # Amenaza media
        } elseif ($devices | Where-Object { $_.ThreatLevel -eq 1 }) {
            exit 1  # Amenaza baja
        } else {
            exit 0  # Sin amenazas
        }
    }
    
} catch {
    Write-SentinelLog "Error crítico: $($_.Exception.Message)" "ERROR" $script:Config.Colors.Error
    Write-SentinelLog "Stack trace: $($_.Exception.StackTrace)" "ERROR" $script:Config.Colors.Error
    exit 5
}

# Ejemplos de uso:
# .\orbix_sentinel_advanced.ps1 -DetailedScan
# .\orbix_sentinel_advanced.ps1 -PortScan -AlertMode
# .\orbix_sentinel_advanced.ps1 -ContinuousMode -ScanInterval 120
# .\orbix_sentinel_advanced.ps1 -OutputFormat JSON -OutputFile "scan_results"
# .\orbix_sentinel_advanced.ps1 -Interface "Wi-Fi" -VulnerabilityCheck
