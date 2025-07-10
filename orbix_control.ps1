# =============================================================================
# Orbix Control Center - Centro de control para Ae.N.K.I y Sentinel
# Autor: Luis Enrique Mata - Orbix AI Systems
# Version: 1.0 - Unified Control Interface
# =============================================================================

param(
    [string]$Action = "help",
    [switch]$Quick,
    [switch]$Detailed,
    [switch]$SaveReports,
    [switch]$Silent,
    [int]$Interval = 30,
    [int]$Count = 5
)

# Configuración de colores
$Colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Aenki = "Blue"
    Sentinel = "Magenta"
    Command = "Yellow"
}

# Función para mostrar mensajes
function Write-ControlLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    if (-not $Silent) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
        Write-Host "[$Level] " -NoNewline -ForegroundColor $Color
        Write-Host $Message -ForegroundColor $Color
    }
}

# Función para mostrar banner
function Show-Banner {
    Write-ControlLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-ControlLog "                      🎮 ORBIX CONTROL CENTER v1.0                            " "INFO" $Colors.Header
    Write-ControlLog "                     🧠 Ae.N.K.I + 🛡️ Sentinel Management                      " "INFO" $Colors.Header
    Write-ControlLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
}

# Función para mostrar ayuda
function Show-Help {
    Show-Banner
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "ACCIONES DISPONIBLES:" "INFO" $Colors.Header
    Write-ControlLog "══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "📊 DIAGNÓSTICO Y ESTADO:" "INFO" $Colors.Command
    Write-ControlLog "  status         - Verificación rápida de estado" "INFO" $Colors.Info
    Write-ControlLog "  detailed       - Diagnóstico completo y detallado" "INFO" $Colors.Info
    Write-ControlLog "  health         - Verificación de salud del sistema" "INFO" $Colors.Info
    Write-ControlLog "  files          - Verificar archivos críticos" "INFO" $Colors.Info
    Write-ControlLog "  network        - Verificar conectividad de red" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "🔄 COMUNICACIÓN:" "INFO" $Colors.Command
    Write-ControlLog "  comm-test      - Test de comunicación bidireccional" "INFO" $Colors.Info
    Write-ControlLog "  comm-monitor   - Monitoreo continuo de comunicación" "INFO" $Colors.Info
    Write-ControlLog "  comm-simulate  - Simulación de intercambio de mensajes" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "🛡️ SEGURIDAD:" "INFO" $Colors.Command
    Write-ControlLog "  scan           - Escaneo básico de red" "INFO" $Colors.Info
    Write-ControlLog "  scan-advanced  - Escaneo avanzado con análisis de amenazas" "INFO" $Colors.Info
    Write-ControlLog "  scan-monitor   - Monitoreo continuo de la red" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "🧠 AE.N.K.I:" "INFO" $Colors.Command
    Write-ControlLog "  aenki-status   - Verificar estado de Ae.N.K.I" "INFO" $Colors.Info
    Write-ControlLog "  aenki-dashboard- Abrir dashboard de Ae.N.K.I" "INFO" $Colors.Info
    Write-ControlLog "  aenki-serve    - Iniciar servidor web para dashboard" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "⚙️ UTILIDADES:" "INFO" $Colors.Command
    Write-ControlLog "  info           - Información del sistema" "INFO" $Colors.Info
    Write-ControlLog "  logs           - Ver logs del sistema" "INFO" $Colors.Info
    Write-ControlLog "  clean          - Limpiar archivos temporales" "INFO" $Colors.Info
    Write-ControlLog "  backup         - Crear respaldo de configuración" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "PARÁMETROS:" "INFO" $Colors.Header
    Write-ControlLog "  -Quick         : Verificación rápida" "INFO" $Colors.Info
    Write-ControlLog "  -Detailed      : Información detallada" "INFO" $Colors.Info
    Write-ControlLog "  -SaveReports   : Guardar reportes en archivos" "INFO" $Colors.Info
    Write-ControlLog "  -Silent        : Modo silencioso" "INFO" $Colors.Info
    Write-ControlLog "  -Interval <n>  : Intervalo para monitoreo (segundos)" "INFO" $Colors.Info
    Write-ControlLog "  -Count <n>     : Número de iteraciones/mensajes" "INFO" $Colors.Info
    Write-ControlLog "" "INFO" $Colors.Info
    Write-ControlLog "EJEMPLOS:" "INFO" $Colors.Header
    Write-ControlLog "  .\orbix_control.ps1 status" "INFO" $Colors.Info
    Write-ControlLog "  .\orbix_control.ps1 detailed -SaveReports" "INFO" $Colors.Info
    Write-ControlLog "  .\orbix_control.ps1 comm-test -Count 10" "INFO" $Colors.Info
    Write-ControlLog "  .\orbix_control.ps1 scan-monitor -Interval 60" "INFO" $Colors.Info
    Write-ControlLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
}

# Función para verificar archivos necesarios
function Test-RequiredFiles {
    $requiredFiles = @(
        ".\orbix_quick_status.ps1",
        ".\orbix_sentinel_advanced.ps1",
        ".\orbix_communication_simulator.ps1",
        ".\orbix_aenki_dashboard.html"
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-ControlLog "❌ Archivos requeridos faltantes:" "ERROR" $Colors.Error
        foreach ($file in $missingFiles) {
            Write-ControlLog "  • $file" "ERROR" $Colors.Error
        }
        return $false
    }
    
    return $true
}

# Función para ejecutar comando con manejo de errores
function Invoke-OrbixCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-ControlLog "Ejecutando: $Description" "CMD" $Colors.Command
    Write-ControlLog "Comando: $Command" "DEBUG" $Colors.Info
    
    try {
        $result = Invoke-Expression $Command
        Write-ControlLog "✅ Comando completado exitosamente" "SUCCESS" $Colors.Success
        return $result
    } catch {
        Write-ControlLog "❌ Error al ejecutar comando: $($_.Exception.Message)" "ERROR" $Colors.Error
        return $null
    }
}

# Función principal para ejecutar acciones
function Invoke-Action {
    param([string]$ActionName)
    
    if (-not (Test-RequiredFiles)) {
        Write-ControlLog "No se pueden ejecutar las acciones sin los archivos requeridos" "ERROR" $Colors.Error
        return
    }
    
    switch ($ActionName.ToLower()) {
        "status" {
            $params = @()
            if ($Quick) { $params += "-Quick" }
            if ($SaveReports) { $params += "-SaveReport" }
            $command = ".\orbix_quick_status.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Verificación rápida de estado"
        }
        
        "detailed" {
            $params = @("-EnhancedDiagnostic")
            if ($SaveReports) { $params += "-SaveReports" }
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Diagnóstico completo y detallado"
        }
        
        "health" {
            $params = @("-StatusCheck")
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Verificación de salud del sistema"
        }
        
        "files" {
            $params = @("-FilesOnly")
            if ($SaveReports) { $params += "-SaveReport" }
            $command = ".\orbix_quick_status.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Verificación de archivos críticos"
        }
        
        "network" {
            $params = @("-NetworkOnly")
            if ($SaveReports) { $params += "-SaveReport" }
            $command = ".\orbix_quick_status.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Verificación de conectividad de red"
        }
        
        "comm-test" {
            $params = @("-CommunicationTest")
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Test de comunicación bidireccional"
        }
        
        "comm-monitor" {
            $params = @("-MonitorCommunication", "-MonitorInterval $Interval", "-MonitorIterations $Count")
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Monitoreo continuo de comunicación"
        }
        
        "comm-simulate" {
            $params = @("-TestMode", "-MessageCount $Count", "-IntervalSeconds $Interval")
            if ($Detailed) { $params += "-Verbose" }
            $command = ".\orbix_communication_simulator.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Simulación de intercambio de mensajes"
        }
        
        "scan" {
            $params = @()
            if ($Quick) { $params += "-Silent" }
            if ($SaveReports) { $params += "-OutputFile orbix_scan_basic.json" }
            $command = ".\orbix_sentinel_escaneo.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Escaneo básico de red"
        }
        
        "scan-advanced" {
            $params = @("-DetailedScan", "-PortScan", "-VulnerabilityCheck")
            if ($SaveReports) { $params += "-OutputFile orbix_scan_advanced.json" }
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Escaneo avanzado con análisis de amenazas"
        }
        
        "scan-monitor" {
            $params = @("-ContinuousMode", "-ScanInterval $Interval", "-AlertMode")
            $command = ".\orbix_sentinel_advanced.ps1 $($params -join ' ')"
            Invoke-OrbixCommand -Command $command -Description "Monitoreo continuo de la red"
        }
        
        "aenki-status" {
            # Verificar estado específico de Ae.N.K.I
            Write-ControlLog "Verificando estado de Ae.N.K.I..." "INFO" $Colors.Aenki
            
            # Verificar archivo del dashboard
            if (Test-Path ".\orbix_aenki_dashboard.html") {
                Write-ControlLog "✅ Dashboard file exists" "SUCCESS" $Colors.Success
            } else {
                Write-ControlLog "❌ Dashboard file missing" "ERROR" $Colors.Error
            }
            
            # Verificar servidor web
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-ControlLog "✅ Web server is running on port 8080" "SUCCESS" $Colors.Success
                } else {
                    Write-ControlLog "⚠️ Web server responding with status $($response.StatusCode)" "WARNING" $Colors.Warning
                }
            } catch {
                Write-ControlLog "❌ Web server not responding on port 8080" "ERROR" $Colors.Error
            }
        }
        
        "aenki-dashboard" {
            Write-ControlLog "Abriendo dashboard de Ae.N.K.I..." "INFO" $Colors.Aenki
            if (Test-Path ".\orbix_aenki_dashboard.html") {
                Start-Process ".\orbix_aenki_dashboard.html"
                Write-ControlLog "✅ Dashboard abierto en el navegador" "SUCCESS" $Colors.Success
            } else {
                Write-ControlLog "❌ Dashboard file not found" "ERROR" $Colors.Error
            }
        }
        
        "aenki-serve" {
            Write-ControlLog "Iniciando servidor web para Ae.N.K.I..." "INFO" $Colors.Aenki
            if (Test-Path ".\orbix_aenki_dashboard.html") {
                # Usar Python para servir el archivo si está disponible
                try {
                    $pythonCmd = "python -m http.server 8080"
                    Write-ControlLog "Comando: $pythonCmd" "INFO" $Colors.Info
                    Write-ControlLog "Servidor iniciado en http://localhost:8080" "SUCCESS" $Colors.Success
                    Write-ControlLog "Presiona Ctrl+C para detener el servidor" "INFO" $Colors.Info
                    Invoke-Expression $pythonCmd
                } catch {
                    Write-ControlLog "❌ Error al iniciar servidor Python. ¿Está Python instalado?" "ERROR" $Colors.Error
                    Write-ControlLog "Intenta abrir el archivo manualmente o usar IIS/Apache" "INFO" $Colors.Info
                }
            } else {
                Write-ControlLog "❌ Dashboard file not found" "ERROR" $Colors.Error
            }
        }
        
        "info" {
            Write-ControlLog "Información del sistema Orbix:" "INFO" $Colors.Header
            Write-ControlLog "• Versión: 1.0" "INFO" $Colors.Info
            Write-ControlLog "• Componentes: Ae.N.K.I + Sentinel" "INFO" $Colors.Info
            Write-ControlLog "• Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO" $Colors.Info
            Write-ControlLog "• PowerShell: $($PSVersionTable.PSVersion)" "INFO" $Colors.Info
            Write-ControlLog "• OS: $([System.Environment]::OSVersion.VersionString)" "INFO" $Colors.Info
            
            # Verificar archivos
            $files = @(
                ".\orbix_aenki_dashboard.html",
                ".\orbix_sentinel_advanced.ps1",
                ".\orbix_sentinel_escaneo.ps1",
                ".\orbix_quick_status.ps1",
                ".\orbix_communication_simulator.ps1",
                ".\orbix_diagnostics.ps1"
            )
            
            Write-ControlLog "Archivos del sistema:" "INFO" $Colors.Info
            foreach ($file in $files) {
                if (Test-Path $file) {
                    $size = (Get-Item $file).Length
                    Write-ControlLog "  ✅ $file ($size bytes)" "SUCCESS" $Colors.Success
                } else {
                    Write-ControlLog "  ❌ $file (missing)" "ERROR" $Colors.Error
                }
            }
        }
        
        "logs" {
            Write-ControlLog "Verificando logs del sistema..." "INFO" $Colors.Info
            $logFiles = @(
                ".\orbix_logs.json",
                ".\orbix_system_status_report.json",
                ".\orbix_complete_diagnostic_report.json",
                ".\orbix_communication_monitoring_report.json"
            )
            
            foreach ($logFile in $logFiles) {
                if (Test-Path $logFile) {
                    $lastWrite = (Get-Item $logFile).LastWriteTime
                    Write-ControlLog "📄 $logFile (última actualización: $lastWrite)" "INFO" $Colors.Info
                } else {
                    Write-ControlLog "📄 $logFile (no existe)" "INFO" $Colors.Warning
                }
            }
        }
        
        "clean" {
            Write-ControlLog "Limpiando archivos temporales..." "INFO" $Colors.Info
            $tempFiles = @(
                ".\orbix_*_test.json",
                ".\orbix_quick_comm_test.json",
                ".\orbix_sentinel_to_aenki*.json",
                ".\orbix_aenki_to_sentinel*.json",
                ".\orbix_test_*.json"
            )
            
            $removedCount = 0
            foreach ($pattern in $tempFiles) {
                $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    Remove-Item $file.FullName -Force
                    $removedCount++
                    Write-ControlLog "🗑️ Eliminado: $($file.Name)" "INFO" $Colors.Info
                }
            }
            
            Write-ControlLog "✅ Limpieza completada ($removedCount archivos eliminados)" "SUCCESS" $Colors.Success
        }
        
        "backup" {
            Write-ControlLog "Creando respaldo de configuración..." "INFO" $Colors.Info
            $backupFolder = ".\orbix_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            
            $configFiles = @(
                ".\orbix_*.json",
                ".\orbix_*.ps1",
                ".\orbix_*.html"
            )
            
            $backedUpCount = 0
            foreach ($pattern in $configFiles) {
                $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    Copy-Item $file.FullName -Destination $backupFolder
                    $backedUpCount++
                    Write-ControlLog "📦 Respaldado: $($file.Name)" "INFO" $Colors.Info
                }
            }
            
            Write-ControlLog "✅ Respaldo completado en $backupFolder ($backedUpCount archivos)" "SUCCESS" $Colors.Success
        }
        
        "help" {
            Show-Help
        }
        
        default {
            Write-ControlLog "❌ Acción no reconocida: $ActionName" "ERROR" $Colors.Error
            Write-ControlLog "Usa 'help' para ver las acciones disponibles" "INFO" $Colors.Info
        }
    }
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

# Mostrar banner si no estamos en modo silencioso
if (-not $Silent) {
    Show-Banner
}

# Ejecutar acción
Invoke-Action -ActionName $Action

# Mostrar mensaje de finalización
if (-not $Silent) {
    Write-ControlLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-ControlLog "Operación completada. Usa '.\orbix_control.ps1 help' para más opciones." "INFO" $Colors.Info
}
