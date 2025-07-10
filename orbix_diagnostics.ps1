# =============================================================================
# Orbix System Diagnostics - Estado de Ae.N.K.I y Sentinel
# Autor: Luis Enrique Mata - Orbix AI Systems
# Version: 1.0 - System Health Monitor
# =============================================================================

param(
    [switch]$ContinuousMonitoring,
    [switch]$SaveReport,
    [string]$AenkiUrl = "http://localhost:8080",
    [switch]$Detailed,
    [switch]$Silent
)

# Configuración
$Colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Critical = "DarkRed"
}

# Banner
if (-not $Silent) {
    Clear-Host
    Write-Host @"
    
╔══════════════════════════════════════════════════════════════════════════════╗
║                     🔍 ORBIX SYSTEM DIAGNOSTICS                            ║
║                   Estado de Ae.N.K.I y Sentinel                           ║
║                        Powered by ORBIX AI                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor $Colors.Header
}

# Función de logging
function Write-DiagLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    if ($Silent) { return }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Función para verificar Ae.N.K.I
function Test-AenkiSystem {
    Write-DiagLog "🧠 Verificando estado de Ae.N.K.I..." "INFO" $Colors.Info
    
    $status = [PSCustomObject]@{
        Name = "Ae.N.K.I"
        Status = "Unknown"
        DashboardFile = "Not Found"
        WebServer = "Offline"
        ResponseTime = 0
        Features = @()
        Errors = @()
        Timestamp = Get-Date
    }
    
    # Verificar archivo del dashboard
    $dashboardPath = ".\orbix_aenki_dashboard.html"
    if (Test-Path $dashboardPath) {
        $status.DashboardFile = "Available"
        Write-DiagLog "  ✅ Dashboard file found" "SUCCESS" $Colors.Success
        
        # Analizar contenido del dashboard
        try {
            $content = Get-Content $dashboardPath -Raw
            
            if ($content -match "Ae\.N\.K\.I") {
                $status.Features += "Avatar System"
            }
            if ($content -match "chat|Chat") {
                $status.Features += "Chat Interface"
            }
            if ($content -match "voice|Voice") {
                $status.Features += "Voice Recognition"
            }
            if ($content -match "sentinel|Sentinel") {
                $status.Features += "Sentinel Integration"
            }
            if ($content -match "Three\.js|three\.js") {
                $status.Features += "3D Avatar"
            }
            
            Write-DiagLog "  📋 Features detected: $($status.Features -join ', ')" "INFO" $Colors.Info
        } catch {
            $status.Errors += "Could not analyze dashboard content"
        }
    } else {
        $status.DashboardFile = "Missing"
        $status.Errors += "Dashboard file not found at $dashboardPath"
        Write-DiagLog "  ❌ Dashboard file not found" "ERROR" $Colors.Error
    }
    
    # Verificar si hay servidor web ejecutándose
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $AenkiUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
        $stopwatch.Stop()
        
        $status.WebServer = "Running"
        $status.ResponseTime = $stopwatch.ElapsedMilliseconds
        $status.Status = "Online"
        
        Write-DiagLog "  ✅ Web server responding ($($status.ResponseTime)ms)" "SUCCESS" $Colors.Success
        
    } catch {
        $status.WebServer = "Not Running"
        $status.Status = "File Only"
        $status.Errors += "Web server not accessible at $AenkiUrl"
        Write-DiagLog "  ⚠️  Web server not running" "WARNING" $Colors.Warning
    }
    
    return $status
}

# Función para verificar Sentinel
function Test-SentinelSystem {
    Write-DiagLog "🛡️ Verificando estado de Sentinel..." "INFO" $Colors.Info
    
    $status = [PSCustomObject]@{
        Name = "Sentinel"
        Status = "Unknown"
        Scripts = @{}
        NetworkCapabilities = @{}
        SystemResources = @{}
        Errors = @()
        Timestamp = Get-Date
    }
    
    # Verificar scripts de Sentinel
    $sentinelScripts = @(
        ".\orbix_sentinel_escaneo.ps1",
        ".\orbix_sentinel_advanced.ps1"
    )
    
    foreach ($script in $sentinelScripts) {
        $scriptName = Split-Path $script -Leaf
        if (Test-Path $script) {
            $status.Scripts[$scriptName] = "Available"
            Write-DiagLog "  ✅ $scriptName found" "SUCCESS" $Colors.Success
        } else {
            $status.Scripts[$scriptName] = "Missing"
            $status.Errors += "$scriptName not found"
            Write-DiagLog "  ❌ $scriptName not found" "ERROR" $Colors.Error
        }
    }
    
    # Verificar capacidades de red
    try {
        $networkInterfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.PrefixOrigin -eq "Dhcp" -and $_.IPAddress -notmatch "^127\." 
        }
        
        if ($networkInterfaces) {
            $status.NetworkCapabilities["Interfaces"] = "Available ($($networkInterfaces.Count))"
            $status.NetworkCapabilities["LocalIP"] = $networkInterfaces[0].IPAddress
            Write-DiagLog "  ✅ Network interfaces available: $($networkInterfaces.Count)" "SUCCESS" $Colors.Success
        } else {
            $status.NetworkCapabilities["Interfaces"] = "None Found"
            $status.Errors += "No active network interfaces"
            Write-DiagLog "  ❌ No network interfaces found" "ERROR" $Colors.Error
        }
    } catch {
        $status.NetworkCapabilities["Interfaces"] = "Error"
        $status.Errors += "Network interface check failed"
    }
    
    # Verificar conectividad
    try {
        $internetTest = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -TimeoutSec 3
        if ($internetTest) {
            $status.NetworkCapabilities["Internet"] = "Available"
            Write-DiagLog "  ✅ Internet connectivity confirmed" "SUCCESS" $Colors.Success
        } else {
            $status.NetworkCapabilities["Internet"] = "Limited"
            $status.Errors += "No internet connectivity"
            Write-DiagLog "  ⚠️  No internet connectivity" "WARNING" $Colors.Warning
        }
    } catch {
        $status.NetworkCapabilities["Internet"] = "Error"
        $status.Errors += "Internet connectivity test failed"
    }
    
    # Verificar tabla ARP
    try {
        $arpEntries = arp -a | Where-Object { $_ -match "^\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s+" }
        if ($arpEntries) {
            $status.NetworkCapabilities["ARP"] = "Available ($($arpEntries.Count) entries)"
            Write-DiagLog "  ✅ ARP table accessible with $($arpEntries.Count) entries" "SUCCESS" $Colors.Success
        } else {
            $status.NetworkCapabilities["ARP"] = "Empty"
            $status.Errors += "ARP table is empty"
        }
    } catch {
        $status.NetworkCapabilities["ARP"] = "Error"
        $status.Errors += "ARP table access failed"
    }
    
    # Verificar recursos del sistema
    try {
        $process = Get-Process -Id $PID
        $status.SystemResources["Memory"] = "$([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
        $status.SystemResources["ProcessID"] = $PID
        
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        $status.SystemResources["AdminRights"] = if ($isAdmin) { "Yes" } else { "No" }
        
        if ($isAdmin) {
            Write-DiagLog "  ✅ Running with administrator privileges" "SUCCESS" $Colors.Success
        } else {
            Write-DiagLog "  ⚠️  Running without administrator privileges" "WARNING" $Colors.Warning
        }
        
    } catch {
        $status.SystemResources["Error"] = "Could not get system resources"
    }
    
    # Determinar estado general
    if ($status.Scripts.Values -contains "Available" -and $status.NetworkCapabilities["Interfaces"] -ne "None Found") {
        $status.Status = "Operational"
    } elseif ($status.Scripts.Values -contains "Available") {
        $status.Status = "Limited"
    } else {
        $status.Status = "Not Available"
    }
    
    return $status
}

# Función para verificar comunicación
function Test-SystemCommunication {
    param($AenkiStatus, $SentinelStatus)
    
    Write-DiagLog "🔗 Verificando comunicación entre sistemas..." "INFO" $Colors.Info
    
    $commStatus = [PSCustomObject]@{
        Status = "Unknown"
        Methods = @()
        TestResults = @{}
        Recommendations = @()
        Errors = @()
    }
    
    # Verificar archivos compartidos
    $sharedFiles = @(
        ".\orbix_config.json",
        ".\orbix_system_status_report.json"
    )
    
    $foundFiles = 0
    foreach ($file in $sharedFiles) {
        if (Test-Path $file) {
            $foundFiles++
            $commStatus.Methods += "Shared Files"
        }
    }
    
    # Crear archivo de prueba de comunicación
    try {
        $testData = @{
            Source = "Diagnostics"
            Target = "Both Systems"
            Timestamp = Get-Date
            Message = "Communication test"
        }
        
        $testFile = ".\orbix_comm_test.json"
        $testData | ConvertTo-Json | Out-File $testFile -Encoding UTF8
        
        if (Test-Path $testFile) {
            $commStatus.TestResults["FileCreation"] = "Success"
            $commStatus.Methods += "JSON Data Exchange"
            
            # Leer archivo de vuelta
            $readData = Get-Content $testFile | ConvertFrom-Json
            if ($readData.Source -eq "Diagnostics") {
                $commStatus.TestResults["FileReadback"] = "Success"
            }
            
            # Limpiar archivo de prueba
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $commStatus.TestResults["FileCreation"] = "Failed"
        $commStatus.Errors += "Could not create communication test file"
    }
    
    # Evaluar estado de comunicación
    if ($AenkiStatus.Status -in @("Online", "File Only") -and $SentinelStatus.Status -eq "Operational") {
        $commStatus.Status = "Ready"
        $commStatus.Recommendations += "Systems are ready for integration"
        
        if ($AenkiStatus.Features -contains "Sentinel Integration") {
            $commStatus.Status = "Integrated"
            $commStatus.Methods += "Dashboard Integration"
        }
    } else {
        $commStatus.Status = "Limited"
        
        if ($AenkiStatus.Status -eq "Unknown") {
            $commStatus.Recommendations += "Start Ae.N.K.I dashboard"
        }
        if ($SentinelStatus.Status -ne "Operational") {
            $commStatus.Recommendations += "Fix Sentinel network issues"
        }
    }
    
    return $commStatus
}

# Función para mostrar resultados
function Show-DiagnosticResults {
    param($AenkiStatus, $SentinelStatus, $CommStatus)
    
    Write-DiagLog "" "INFO" $Colors.Info
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host "                           📊 REPORTE DE DIAGNÓSTICO                           " -ForegroundColor $Colors.Header
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    
    # Estado de Ae.N.K.I
    Write-Host ""
    Write-Host "🧠 AE.N.K.I STATUS:" -ForegroundColor $Colors.Header
    Write-Host "─────────────────────────────────────────────────────────────────────────────" -ForegroundColor $Colors.Header
    
    $aenkiColor = switch ($AenkiStatus.Status) {
        "Online" { $Colors.Success }
        "File Only" { $Colors.Warning }
        default { $Colors.Error }
    }
    
    Write-Host "Estado: $($AenkiStatus.Status)" -ForegroundColor $aenkiColor
    Write-Host "Dashboard: $($AenkiStatus.DashboardFile)" -ForegroundColor $(if ($AenkiStatus.DashboardFile -eq "Available") { $Colors.Success } else { $Colors.Error })
    Write-Host "Servidor Web: $($AenkiStatus.WebServer)" -ForegroundColor $(if ($AenkiStatus.WebServer -eq "Running") { $Colors.Success } else { $Colors.Warning })
    
    if ($AenkiStatus.ResponseTime -gt 0) {
        Write-Host "Tiempo de respuesta: $($AenkiStatus.ResponseTime)ms" -ForegroundColor $Colors.Info
    }
    
    if ($AenkiStatus.Features.Count -gt 0) {
        Write-Host "Características: $($AenkiStatus.Features -join ', ')" -ForegroundColor $Colors.Info
    }
    
    if ($AenkiStatus.Errors.Count -gt 0) {
        Write-Host "Errores:" -ForegroundColor $Colors.Error
        foreach ($err in $AenkiStatus.Errors) {
            Write-Host "  • $err" -ForegroundColor $Colors.Error
        }
    }
    
    # Estado de Sentinel
    Write-Host ""
    Write-Host "🛡️ SENTINEL STATUS:" -ForegroundColor $Colors.Header
    Write-Host "─────────────────────────────────────────────────────────────────────────────" -ForegroundColor $Colors.Header
    
    $sentinelColor = switch ($SentinelStatus.Status) {
        "Operational" { $Colors.Success }
        "Limited" { $Colors.Warning }
        default { $Colors.Error }
    }
    
    Write-Host "Estado: $($SentinelStatus.Status)" -ForegroundColor $sentinelColor
    
    Write-Host "Scripts disponibles:" -ForegroundColor $Colors.Info
    foreach ($script in $SentinelStatus.Scripts.GetEnumerator()) {
        $scriptColor = if ($script.Value -eq "Available") { $Colors.Success } else { $Colors.Error }
        Write-Host "  • $($script.Key): $($script.Value)" -ForegroundColor $scriptColor
    }
    
    Write-Host "Capacidades de red:" -ForegroundColor $Colors.Info
    foreach ($capability in $SentinelStatus.NetworkCapabilities.GetEnumerator()) {
        $capColor = if ($capability.Value -match "Available|Yes") { $Colors.Success } else { $Colors.Warning }
        Write-Host "  • $($capability.Key): $($capability.Value)" -ForegroundColor $capColor
    }
    
    Write-Host "Recursos del sistema:" -ForegroundColor $Colors.Info
    foreach ($resource in $SentinelStatus.SystemResources.GetEnumerator()) {
        Write-Host "  • $($resource.Key): $($resource.Value)" -ForegroundColor $Colors.Info
    }
    
    if ($SentinelStatus.Errors.Count -gt 0) {
        Write-Host "Errores:" -ForegroundColor $Colors.Error
        foreach ($err in $SentinelStatus.Errors) {
            Write-Host "  • $err" -ForegroundColor $Colors.Error
        }
    }
    
    # Estado de comunicación
    Write-Host ""
    Write-Host "🔗 COMUNICACIÓN ENTRE SISTEMAS:" -ForegroundColor $Colors.Header
    Write-Host "─────────────────────────────────────────────────────────────────────────────" -ForegroundColor $Colors.Header
    
    $commColor = switch ($CommStatus.Status) {
        "Integrated" { $Colors.Success }
        "Ready" { $Colors.Success }
        "Limited" { $Colors.Warning }
        default { $Colors.Error }
    }
    
    Write-Host "Estado: $($CommStatus.Status)" -ForegroundColor $commColor
    
    if ($CommStatus.Methods.Count -gt 0) {
        Write-Host "Métodos disponibles: $($CommStatus.Methods -join ', ')" -ForegroundColor $Colors.Info
    }
    
    if ($CommStatus.TestResults.Count -gt 0) {
        Write-Host "Resultados de pruebas:" -ForegroundColor $Colors.Info
        foreach ($test in $CommStatus.TestResults.GetEnumerator()) {
            $testColor = if ($test.Value -eq "Success") { $Colors.Success } else { $Colors.Error }
            Write-Host "  • $($test.Key): $($test.Value)" -ForegroundColor $testColor
        }
    }
    
    if ($CommStatus.Recommendations.Count -gt 0) {
        Write-Host "Recomendaciones:" -ForegroundColor $Colors.Warning
        foreach ($rec in $CommStatus.Recommendations) {
            Write-Host "  • $rec" -ForegroundColor $Colors.Warning
        }
    }
    
    # Resumen general
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    Write-Host "                              📋 RESUMEN GENERAL                              " -ForegroundColor $Colors.Header
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    
    $overallStatus = "Unknown"
    $overallColor = $Colors.Info
    
    if ($AenkiStatus.Status -eq "Online" -and $SentinelStatus.Status -eq "Operational" -and $CommStatus.Status -in @("Integrated", "Ready")) {
        $overallStatus = "🟢 SISTEMA COMPLETAMENTE FUNCIONAL"
        $overallColor = $Colors.Success
    } elseif ($AenkiStatus.DashboardFile -eq "Available" -and $SentinelStatus.Scripts.Values -contains "Available") {
        $overallStatus = "🟡 SISTEMA LISTO PARA ACTIVAR"
        $overallColor = $Colors.Warning
    } else {
        $overallStatus = "🔴 SISTEMA REQUIERE CONFIGURACIÓN"
        $overallColor = $Colors.Error
    }
    
    Write-Host $overallStatus -ForegroundColor $overallColor
    
    $totalErrors = $AenkiStatus.Errors.Count + $SentinelStatus.Errors.Count + $CommStatus.Errors.Count
    if ($totalErrors -eq 0) {
        Write-Host "✅ No se encontraron errores críticos" -ForegroundColor $Colors.Success
    } else {
        Write-Host "⚠️  Total de problemas encontrados: $totalErrors" -ForegroundColor $Colors.Warning
    }
    
    Write-Host ""
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Colors.Info
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor $Colors.Header
    
    return @{
        OverallStatus = $overallStatus
        AenkiStatus = $AenkiStatus
        SentinelStatus = $SentinelStatus
        CommunicationStatus = $CommStatus
        TotalErrors = $totalErrors
        Timestamp = Get-Date
    }
}

# Función principal
function Start-Diagnostics {
    Write-DiagLog "🔍 Iniciando diagnóstico completo del sistema ORBIX..." "INFO" $Colors.Header
    
    # Verificar sistemas
    $aenkiStatus = Test-AenkiSystem
    $sentinelStatus = Test-SentinelSystem
    $commStatus = Test-SystemCommunication -AenkiStatus $aenkiStatus -SentinelStatus $sentinelStatus
    
    # Mostrar resultados
    $report = Show-DiagnosticResults -AenkiStatus $aenkiStatus -SentinelStatus $sentinelStatus -CommStatus $commStatus
    
    # Guardar reporte si se solicita
    if ($SaveReport) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $reportFile = ".\orbix_diagnostic_report_$timestamp.json"
            $report | ConvertTo-Json -Depth 5 | Out-File $reportFile -Encoding UTF8
            Write-DiagLog "📄 Reporte guardado en: $reportFile" "SUCCESS" $Colors.Success
        } catch {
            Write-DiagLog "❌ No se pudo guardar el reporte" "ERROR" $Colors.Error
        }
    }
    
    return $report
}

# EJECUCIÓN PRINCIPAL
try {
    if ($ContinuousMonitoring) {
        Write-DiagLog "🔄 Iniciando monitoreo continuo..." "INFO" $Colors.Info
        
        while ($true) {
            $report = Start-Diagnostics
            Write-DiagLog "⏱️  Próximo diagnóstico en 60 segundos..." "INFO" $Colors.Info
            Start-Sleep -Seconds 60
        }
    } else {
        $report = Start-Diagnostics
        
        # Códigos de salida
        if ($report.TotalErrors -eq 0) {
            exit 0  # Todo bien
        } elseif ($report.TotalErrors -le 3) {
            exit 1  # Problemas menores
        } else {
            exit 2  # Problemas significativos
        }
    }
    
} catch {
    Write-DiagLog "❌ Error crítico en diagnóstico: $($_.Exception.Message)" "ERROR" $Colors.Error
    exit 3
}

# Ejemplos de uso:
# .\orbix_diagnostics.ps1
# .\orbix_diagnostics.ps1 -SaveReport
# .\orbix_diagnostics.ps1 -ContinuousMonitoring
# .\orbix_diagnostics.ps1 -AenkiUrl "http://192.168.1.100:8080"
# .\orbix_diagnostics.ps1 -Detailed -SaveReport
