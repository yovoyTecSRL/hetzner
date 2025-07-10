# =============================================================================
# Orbix Status Check - Verificación rápida de estado y comunicación
# Autor: Luis Enrique Mata - Orbix AI Systems
# Version: 1.0 - Quick Status Check
# =============================================================================

param(
    [switch]$Quick,
    [switch]$Detailed,
    [switch]$CommunicationOnly,
    [switch]$FilesOnly,
    [switch]$NetworkOnly,
    [switch]$SaveReport
)

# Configuración de colores
$Colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Suspicious = "Magenta"
}

# Función para mostrar mensajes con colores
function Write-StatusLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "[$Level] " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor $Color
}

# Función para verificar estado básico de Ae.N.K.I
function Test-AenkiQuickStatus {
    Write-StatusLog "Verificando Ae.N.K.I..." "CHECK" $Colors.Info
    
    $status = [PSCustomObject]@{
        Name = "Ae.N.K.I"
        Status = "Unknown"
        DashboardFile = "Unknown"
        WebServer = "Unknown"
        Port8080 = "Unknown"
        ResponseTime = 0
        Errors = @()
    }
    
    # Verificar archivo del dashboard
    if (Test-Path ".\orbix_aenki_dashboard.html") {
        $status.DashboardFile = "✅ Existe"
        $fileSize = (Get-Item ".\orbix_aenki_dashboard.html").Length
        if ($fileSize -gt 10000) {
            $status.DashboardFile += " (${fileSize} bytes)"
        } else {
            $status.DashboardFile += " ⚠️ Archivo pequeño"
        }
    } else {
        $status.DashboardFile = "❌ No encontrado"
        $status.Errors += "Dashboard file missing"
    }
    
    # Verificar servidor web
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5 -ErrorAction SilentlyContinue
        $stopwatch.Stop()
        
        if ($response.StatusCode -eq 200) {
            $status.WebServer = "✅ Activo"
            $status.Port8080 = "✅ Respondiendo"
            $status.ResponseTime = $stopwatch.ElapsedMilliseconds
            $status.Status = "Online"
        } else {
            $status.WebServer = "⚠️ Respuesta inválida"
            $status.Port8080 = "⚠️ Error HTTP $($response.StatusCode)"
            $status.Status = "Degraded"
        }
    } catch {
        $status.WebServer = "❌ No activo"
        $status.Port8080 = "❌ Sin respuesta"
        $status.Status = "Offline"
        $status.Errors += "Web server not responding"
    }
    
    return $status
}

# Función para verificar estado básico de Sentinel
function Test-SentinelQuickStatus {
    Write-StatusLog "Verificando Sentinel..." "CHECK" $Colors.Info
    
    $status = [PSCustomObject]@{
        Name = "Sentinel"
        Status = "Unknown"
        ScriptFile = "Unknown"
        Network = "Unknown"
        ARP = "Unknown"
        ProcessActive = "Unknown"
        Errors = @()
    }
    
    # Verificar archivos de script
    $scripts = @(".\orbix_sentinel_advanced.ps1", ".\orbix_sentinel_escaneo.ps1")
    $existingScripts = 0
    
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            $existingScripts++
        }
    }
    
    if ($existingScripts -eq 2) {
        $status.ScriptFile = "✅ Todos los scripts disponibles"
    } elseif ($existingScripts -eq 1) {
        $status.ScriptFile = "⚠️ Scripts parciales"
    } else {
        $status.ScriptFile = "❌ Scripts no encontrados"
        $status.Errors += "Sentinel scripts missing"
    }
    
    # Verificar red
    try {
        $networkInterface = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.PrefixOrigin -eq "Dhcp" -and $_.IPAddress -notmatch "^127\." 
        } | Select-Object -First 1
        
        if ($networkInterface) {
            $status.Network = "✅ Activa ($($networkInterface.IPAddress))"
        } else {
            $status.Network = "❌ Sin red activa"
            $status.Errors += "No active network"
        }
    } catch {
        $status.Network = "❌ Error de red"
        $status.Errors += "Network check failed"
    }
    
    # Verificar ARP
    try {
        $arpEntries = arp -a | Where-Object { $_ -match "^\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" }
        if ($arpEntries -and $arpEntries.Count -gt 0) {
            $status.ARP = "✅ Disponible ($($arpEntries.Count) entradas)"
        } else {
            $status.ARP = "⚠️ Tabla vacía"
        }
    } catch {
        $status.ARP = "❌ Error ARP"
        $status.Errors += "ARP table error"
    }
    
    # Verificar proceso actual
    $status.ProcessActive = "✅ Activo (PID: $PID)"
    
    # Determinar estado general
    if ($status.Errors.Count -eq 0) {
        $status.Status = "Active"
    } elseif ($status.Errors.Count -le 2) {
        $status.Status = "Degraded"
    } else {
        $status.Status = "Critical"
    }
    
    return $status
}

# Función para verificar comunicación rápida
function Test-QuickCommunication {
    Write-StatusLog "Verificando comunicación..." "CHECK" $Colors.Info
    
    $status = [PSCustomObject]@{
        Status = "Unknown"
        FileBasedComm = "Unknown"
        WebBasedComm = "Unknown"
        SharedFiles = @()
        TestResults = @()
        Recommendations = @()
        Errors = @()
    }
    
    # Verificar archivos compartidos
    $sharedFiles = @(
        ".\orbix_shared_data.json",
        ".\orbix_config.json",
        ".\orbix_system_status_report.json"
    )
    
    $existingSharedFiles = 0
    foreach ($file in $sharedFiles) {
        if (Test-Path $file) {
            $existingSharedFiles++
            $status.SharedFiles += $file
        }
    }
    
    if ($existingSharedFiles -gt 0) {
        $status.FileBasedComm = "✅ Disponible ($existingSharedFiles archivos)"
    } else {
        $status.FileBasedComm = "❌ No disponible"
        $status.Errors += "No shared files found"
    }
    
    # Verificar comunicación web
    try {
        $webTest = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($webTest.StatusCode -eq 200) {
            $status.WebBasedComm = "✅ Disponible"
        } else {
            $status.WebBasedComm = "⚠️ Respuesta parcial"
        }
    } catch {
        $status.WebBasedComm = "❌ No disponible"
        $status.Errors += "Web communication not available"
    }
    
    # Crear archivo de test de comunicación
    $testFile = ".\orbix_quick_comm_test.json"
    try {
        $testData = @{
            Source = "StatusCheck"
            Timestamp = Get-Date
            TestMessage = "Communication test from status check"
            RequestId = [System.Guid]::NewGuid().ToString()
        }
        
        $testData | ConvertTo-Json | Out-File -FilePath $testFile -Encoding UTF8
        
        if (Test-Path $testFile) {
            $status.TestResults += "✅ Archivo de test creado"
            
            # Simular lectura
            $readData = Get-Content $testFile | ConvertFrom-Json
            if ($readData.Source -eq "StatusCheck") {
                $status.TestResults += "✅ Lectura de archivo exitosa"
            }
            
            # Limpiar
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $status.TestResults += "❌ Error en test de archivo"
        $status.Errors += "File communication test failed"
    }
    
    # Determinar estado general
    if ($status.FileBasedComm -like "*✅*" -or $status.WebBasedComm -like "*✅*") {
        $status.Status = "Functional"
    } elseif ($status.FileBasedComm -like "*⚠️*" -or $status.WebBasedComm -like "*⚠️*") {
        $status.Status = "Limited"
    } else {
        $status.Status = "Failed"
    }
    
    # Generar recomendaciones
    if ($status.Status -eq "Failed") {
        $status.Recommendations += "Start Ae.N.K.I web server"
        $status.Recommendations += "Create shared configuration files"
    } elseif ($status.Status -eq "Limited") {
        $status.Recommendations += "Verify web server configuration"
        $status.Recommendations += "Check file permissions"
    }
    
    return $status
}

# Función para verificar archivos críticos
function Test-CriticalFiles {
    Write-StatusLog "Verificando archivos críticos..." "CHECK" $Colors.Info
    
    $status = [PSCustomObject]@{
        Status = "Unknown"
        TotalFiles = 0
        ExistingFiles = 0
        MissingFiles = @()
        FileDetails = @()
        Errors = @()
    }
    
    $criticalFiles = @(
        @{ Path = ".\orbix_aenki_dashboard.html"; Required = $true; Description = "Ae.N.K.I Dashboard" },
        @{ Path = ".\orbix_sentinel_advanced.ps1"; Required = $true; Description = "Sentinel Advanced" },
        @{ Path = ".\orbix_sentinel_escaneo.ps1"; Required = $true; Description = "Sentinel Basic" },
        @{ Path = ".\orbix_diagnostics.ps1"; Required = $false; Description = "Diagnostics Script" }
    )
    
    $status.TotalFiles = $criticalFiles.Count
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file.Path) {
            $status.ExistingFiles++
            $fileInfo = Get-Item $file.Path
            $status.FileDetails += [PSCustomObject]@{
                Path = $file.Path
                Description = $file.Description
                Size = $fileInfo.Length
                LastModified = $fileInfo.LastWriteTime
                Status = "✅ Existe"
            }
        } else {
            $status.MissingFiles += $file.Path
            $status.FileDetails += [PSCustomObject]@{
                Path = $file.Path
                Description = $file.Description
                Size = 0
                LastModified = $null
                Status = "❌ Faltante"
            }
            
            if ($file.Required) {
                $status.Errors += "Critical file missing: $($file.Path)"
            }
        }
    }
    
    # Determinar estado
    if ($status.ExistingFiles -eq $status.TotalFiles) {
        $status.Status = "All Files OK"
    } elseif ($status.Errors.Count -eq 0) {
        $status.Status = "Optional Files Missing"
    } else {
        $status.Status = "Critical Files Missing"
    }
    
    return $status
}

# Función principal de verificación rápida
function Start-QuickStatusCheck {
    Write-StatusLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-StatusLog "                      🔍 ORBIX QUICK STATUS CHECK                              " "INFO" $Colors.Header
    Write-StatusLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    $overallStatus = [PSCustomObject]@{
        Timestamp = Get-Date
        OverallHealth = "Unknown"
        Components = @{}
        Summary = @{}
        Recommendations = @()
        Errors = @()
    }
    
    # Verificar componentes según parámetros
    if (-not $CommunicationOnly -and -not $FilesOnly -and -not $NetworkOnly) {
        # Verificación completa por defecto
        $overallStatus.Components.Aenki = Test-AenkiQuickStatus
        $overallStatus.Components.Sentinel = Test-SentinelQuickStatus
        $overallStatus.Components.Communication = Test-QuickCommunication
        $overallStatus.Components.Files = Test-CriticalFiles
    } else {
        # Verificaciones específicas
        if ($CommunicationOnly) {
            $overallStatus.Components.Communication = Test-QuickCommunication
        }
        if ($FilesOnly) {
            $overallStatus.Components.Files = Test-CriticalFiles
        }
        if ($NetworkOnly) {
            $overallStatus.Components.Sentinel = Test-SentinelQuickStatus
        }
    }
    
    # Mostrar resultados
    Write-StatusLog "" "INFO" $Colors.Info
    Write-StatusLog "📊 RESULTADOS:" "INFO" $Colors.Header
    Write-StatusLog "─────────────────────────────────────────────────────────────────────────────" "INFO" $Colors.Header
    
    $healthyComponents = 0
    $totalComponents = 0
    
    foreach ($component in $overallStatus.Components.GetEnumerator()) {
        $totalComponents++
        Write-StatusLog "" "INFO" $Colors.Info
        Write-StatusLog "🔹 $($component.Key.ToUpper()):" "INFO" $Colors.Info
        
        $comp = $component.Value
        $statusColor = $Colors.Info
        
        if ($comp.Status -like "*Online*" -or $comp.Status -like "*Active*" -or $comp.Status -like "*OK*" -or $comp.Status -like "*Functional*") {
            $statusColor = $Colors.Success
            $healthyComponents++
        } elseif ($comp.Status -like "*Degraded*" -or $comp.Status -like "*Limited*" -or $comp.Status -like "*Missing*") {
            $statusColor = $Colors.Warning
        } else {
            $statusColor = $Colors.Error
        }
        
        Write-StatusLog "  Estado: $($comp.Status)" "STATUS" $statusColor
        
        # Mostrar detalles específicos por componente
        if ($component.Key -eq "Aenki") {
            Write-StatusLog "  Dashboard: $($comp.DashboardFile)" "INFO" $Colors.Info
            Write-StatusLog "  Web Server: $($comp.WebServer)" "INFO" $Colors.Info
            Write-StatusLog "  Puerto 8080: $($comp.Port8080)" "INFO" $Colors.Info
            if ($comp.ResponseTime -gt 0) {
                Write-StatusLog "  Tiempo de respuesta: $($comp.ResponseTime)ms" "INFO" $Colors.Info
            }
        } elseif ($component.Key -eq "Sentinel") {
            Write-StatusLog "  Scripts: $($comp.ScriptFile)" "INFO" $Colors.Info
            Write-StatusLog "  Red: $($comp.Network)" "INFO" $Colors.Info
            Write-StatusLog "  ARP: $($comp.ARP)" "INFO" $Colors.Info
            Write-StatusLog "  Proceso: $($comp.ProcessActive)" "INFO" $Colors.Info
        } elseif ($component.Key -eq "Communication") {
            Write-StatusLog "  Archivos: $($comp.FileBasedComm)" "INFO" $Colors.Info
            Write-StatusLog "  Web: $($comp.WebBasedComm)" "INFO" $Colors.Info
            if ($comp.SharedFiles.Count -gt 0) {
                Write-StatusLog "  Archivos compartidos: $($comp.SharedFiles.Count)" "INFO" $Colors.Info
            }
        } elseif ($component.Key -eq "Files") {
            Write-StatusLog "  Archivos: $($comp.ExistingFiles)/$($comp.TotalFiles)" "INFO" $Colors.Info
            if ($comp.MissingFiles.Count -gt 0) {
                Write-StatusLog "  Faltantes: $($comp.MissingFiles.Count)" "WARNING" $Colors.Warning
            }
        }
        
        # Mostrar errores si existen
        if ($comp.Errors.Count -gt 0) {
            Write-StatusLog "  Errores: $($comp.Errors.Count)" "ERROR" $Colors.Error
            $overallStatus.Errors += $comp.Errors
        }
        
        # Agregar recomendaciones
        if ($comp.Recommendations.Count -gt 0) {
            $overallStatus.Recommendations += $comp.Recommendations
        }
    }
    
    # Calcular salud general
    $healthPercentage = if ($totalComponents -gt 0) { ($healthyComponents / $totalComponents) * 100 } else { 0 }
    
    if ($healthPercentage -ge 80) {
        $overallStatus.OverallHealth = "🟢 SALUDABLE"
        $healthColor = $Colors.Success
    } elseif ($healthPercentage -ge 60) {
        $overallStatus.OverallHealth = "🟡 ACEPTABLE"
        $healthColor = $Colors.Warning
    } else {
        $overallStatus.OverallHealth = "🔴 CRÍTICO"
        $healthColor = $Colors.Error
    }
    
    # Mostrar resumen
    Write-StatusLog "" "INFO" $Colors.Info
    Write-StatusLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-StatusLog "                              📋 RESUMEN                                      " "INFO" $Colors.Header
    Write-StatusLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    Write-StatusLog "Estado general: $($overallStatus.OverallHealth)" "OVERALL" $healthColor
    Write-StatusLog "Componentes saludables: $healthyComponents/$totalComponents ($([math]::Round($healthPercentage, 1))%)" "INFO" $Colors.Info
    Write-StatusLog "Total de errores: $($overallStatus.Errors.Count)" "INFO" $(if ($overallStatus.Errors.Count -eq 0) { $Colors.Success } else { $Colors.Error })
    Write-StatusLog "Verificado en: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO" $Colors.Info
    
    if ($overallStatus.Recommendations.Count -gt 0) {
        Write-StatusLog "" "INFO" $Colors.Info
        Write-StatusLog "Recomendaciones:" "INFO" $Colors.Warning
        $priorityRecs = $overallStatus.Recommendations | Select-Object -Unique | Select-Object -First 3
        foreach ($rec in $priorityRecs) {
            Write-StatusLog "  • $rec" "REC" $Colors.Warning
        }
    }
    
    Write-StatusLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    # Guardar reporte si se solicita
    if ($SaveReport) {
        try {
            $overallStatus | ConvertTo-Json -Depth 4 | Out-File -FilePath ".\orbix_quick_status_report.json" -Encoding UTF8
            Write-StatusLog "📄 Reporte guardado en: orbix_quick_status_report.json" "INFO" $Colors.Success
        } catch {
            Write-StatusLog "❌ No se pudo guardar el reporte" "ERROR" $Colors.Error
        }
    }
    
    return $overallStatus
}

# =============================================================================
# EJECUCIÓN
# =============================================================================

# Ejecutar verificación rápida
$result = Start-QuickStatusCheck

# Código de salida basado en el estado
if ($result.OverallHealth -like "*🟢*") {
    exit 0
} elseif ($result.OverallHealth -like "*🟡*") {
    exit 1
} else {
    exit 2
}
