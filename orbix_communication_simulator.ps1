# =============================================================================
# Orbix Communication Simulator - Simular intercambio de datos
# Autor: Luis Enrique Mata - Orbix AI Systems
# Version: 1.0 - Communication Simulator
# =============================================================================

param(
    [switch]$StartAsAenki,
    [switch]$StartAsSentinel,
    [switch]$TestMode,
    [int]$MessageCount = 5,
    [int]$IntervalSeconds = 2,
    [switch]$Verbose
)

# Configuración
$Colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Aenki = "Blue"
    Sentinel = "Magenta"
}

# Función para mostrar mensajes
function Write-CommLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White",
        [string]$Source = ""
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $sourcePrefix = if ($Source) { "[$Source] " } else { "" }
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host "$sourcePrefix" -NoNewline -ForegroundColor $Color
    Write-Host "[$Level] " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor $Color
}

# Función para crear mensaje de Sentinel
function New-SentinelMessage {
    param(
        [string]$MessageType = "NetworkScanUpdate",
        [string]$RequestId = ""
    )
    
    if (-not $RequestId) {
        $RequestId = [System.Guid]::NewGuid().ToString()
    }
    
    $message = @{
        Source = "Sentinel"
        Target = "Ae.N.K.I"
        MessageType = $MessageType
        RequestId = $RequestId
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        Data = @{}
    }
    
    switch ($MessageType) {
        "NetworkScanUpdate" {
            $message.Data = @{
                ScanResults = @{
                    DevicesFound = Get-Random -Minimum 3 -Maximum 12
                    ThreatsDetected = Get-Random -Minimum 0 -Maximum 3
                    ScanDuration = Get-Random -Minimum 15 -Maximum 45
                    NewDevices = Get-Random -Minimum 0 -Maximum 2
                }
                NetworkInfo = @{
                    LocalIP = "192.168.1.$(Get-Random -Minimum 100 -Maximum 199)"
                    ActiveInterfaces = 1
                    InternetConnectivity = "Available"
                }
                SystemStatus = @{
                    MemoryUsage = Get-Random -Minimum 80 -Maximum 200
                    CPUUsage = Get-Random -Minimum 10 -Maximum 40
                    ActiveScans = Get-Random -Minimum 0 -Maximum 3
                }
            }
        }
        "ThreatAlert" {
            $message.Data = @{
                Alert = @{
                    Level = "High"
                    Device = "192.168.1.$(Get-Random -Minimum 100 -Maximum 199)"
                    ThreatType = "Suspicious Device"
                    Details = "Unknown MAC address pattern detected"
                    Timestamp = Get-Date
                }
            }
        }
        "StatusUpdate" {
            $message.Data = @{
                Status = "Active"
                Version = "3.0"
                Capabilities = @("Network Scanning", "Threat Detection", "Port Scanning")
                Performance = @{
                    UptimeMinutes = Get-Random -Minimum 30 -Maximum 1440
                    LastScanTime = (Get-Date).AddMinutes(-$(Get-Random -Minimum 1 -Maximum 30))
                }
            }
        }
    }
    
    return $message
}

# Función para crear mensaje de Ae.N.K.I
function New-AenkiMessage {
    param(
        [string]$MessageType = "StatusResponse",
        [string]$ResponseTo = "",
        [string]$RequestId = ""
    )
    
    if (-not $RequestId) {
        $RequestId = [System.Guid]::NewGuid().ToString()
    }
    
    $message = @{
        Source = "Ae.N.K.I"
        Target = "Sentinel"
        MessageType = $MessageType
        RequestId = $RequestId
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        Data = @{}
    }
    
    if ($ResponseTo) {
        $message.ResponseTo = $ResponseTo
    }
    
    switch ($MessageType) {
        "StatusResponse" {
            $message.Data = @{
                Status = "Online"
                Version = "1.0"
                Services = @{
                    Dashboard = "Active"
                    Avatar = "Active"
                    ChatSystem = "Active"
                    VoiceSystem = "Active"
                }
                Performance = @{
                    ResponseTime = Get-Random -Minimum 50 -Maximum 200
                    ActiveConnections = Get-Random -Minimum 0 -Maximum 5
                }
            }
        }
        "Command" {
            $commands = @(
                "Continue monitoring",
                "Increase scan frequency",
                "Generate detailed report",
                "Alert on new devices",
                "Reduce scan interval"
            )
            $message.Data = @{
                Command = $commands | Get-Random
                Parameters = @{
                    Priority = "Normal"
                    Execute = $true
                }
            }
        }
        "ConfigUpdate" {
            $message.Data = @{
                Configuration = @{
                    AlertThreshold = "Medium"
                    ScanInterval = 300
                    ReportFrequency = "Every 10 minutes"
                    EnableAudioAlerts = $true
                }
            }
        }
    }
    
    return $message
}

# Función para enviar mensaje (simulado con archivo)
function Send-Message {
    param(
        [object]$Message,
        [string]$FilePath
    )
    
    try {
        $Message | ConvertTo-Json -Depth 4 | Out-File -FilePath $FilePath -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

# Función para recibir mensaje
function Receive-Message {
    param(
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        try {
            $content = Get-Content $FilePath | ConvertFrom-Json
            return $content
        } catch {
            return $null
        }
    }
    return $null
}

# Función para simular Sentinel
function Start-SentinelSimulation {
    param(
        [int]$MessageCount,
        [int]$IntervalSeconds
    )
    
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-CommLog "                      🛡️ SENTINEL COMMUNICATION SIMULATOR                      " "INFO" $Colors.Header "SENTINEL"
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    $sentinelToAenkiFile = ".\orbix_sentinel_to_aenki.json"
    $aenkiToSentinelFile = ".\orbix_aenki_to_sentinel.json"
    
    for ($i = 1; $i -le $MessageCount; $i++) {
        Write-CommLog "Enviando mensaje $i de $MessageCount..." "SEND" $Colors.Sentinel "SENTINEL"
        
        # Crear mensaje de Sentinel
        $messageTypes = @("NetworkScanUpdate", "StatusUpdate", "ThreatAlert")
        $messageType = $messageTypes | Get-Random
        $message = New-SentinelMessage -MessageType $messageType
        
        # Enviar mensaje
        if (Send-Message -Message $message -FilePath $sentinelToAenkiFile) {
            Write-CommLog "✅ Mensaje enviado: $messageType" "SUCCESS" $Colors.Success "SENTINEL"
            
            if ($Verbose) {
                Write-CommLog "📋 Contenido: $($message.Data | ConvertTo-Json -Compress)" "DEBUG" $Colors.Info "SENTINEL"
            }
        } else {
            Write-CommLog "❌ Error al enviar mensaje" "ERROR" $Colors.Error "SENTINEL"
        }
        
        # Esperar respuesta de Ae.N.K.I
        $waitTime = 0
        $maxWait = 5
        while ($waitTime -lt $maxWait) {
            Start-Sleep -Seconds 1
            $waitTime++
            
            $response = Receive-Message -FilePath $aenkiToSentinelFile
            if ($response -and $response.ResponseTo -eq $message.RequestId) {
                Write-CommLog "📨 Respuesta recibida de Ae.N.K.I: $($response.MessageType)" "RECEIVE" $Colors.Success "SENTINEL"
                
                if ($Verbose) {
                    Write-CommLog "📋 Respuesta: $($response.Data | ConvertTo-Json -Compress)" "DEBUG" $Colors.Info "SENTINEL"
                }
                
                # Limpiar archivo de respuesta
                Remove-Item $aenkiToSentinelFile -Force -ErrorAction SilentlyContinue
                break
            }
        }
        
        if ($waitTime -ge $maxWait) {
            Write-CommLog "⏰ Timeout esperando respuesta de Ae.N.K.I" "WARNING" $Colors.Warning "SENTINEL"
        }
        
        # Limpiar archivo de envío
        Remove-Item $sentinelToAenkiFile -Force -ErrorAction SilentlyContinue
        
        if ($i -lt $MessageCount) {
            Write-CommLog "Esperando $IntervalSeconds segundos..." "WAIT" $Colors.Info "SENTINEL"
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    
    Write-CommLog "🏁 Simulación de Sentinel completada" "INFO" $Colors.Success "SENTINEL"
}

# Función para simular Ae.N.K.I
function Start-AenkiSimulation {
    param(
        [int]$MessageCount,
        [int]$IntervalSeconds
    )
    
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-CommLog "                      🧠 AE.N.K.I COMMUNICATION SIMULATOR                      " "INFO" $Colors.Header "AE.N.K.I"
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    $sentinelToAenkiFile = ".\orbix_sentinel_to_aenki.json"
    $aenkiToSentinelFile = ".\orbix_aenki_to_sentinel.json"
    
    $messagesProcessed = 0
    $maxWaitCycles = $MessageCount * 10  # Esperar suficiente tiempo para recibir todos los mensajes
    
    for ($cycle = 1; $cycle -le $maxWaitCycles; $cycle++) {
        # Verificar si hay mensajes de Sentinel
        $incomingMessage = Receive-Message -FilePath $sentinelToAenkiFile
        
        if ($incomingMessage -and $incomingMessage.Source -eq "Sentinel") {
            $messagesProcessed++
            Write-CommLog "📨 Mensaje recibido de Sentinel: $($incomingMessage.MessageType)" "RECEIVE" $Colors.Success "AE.N.K.I"
            
            if ($Verbose) {
                Write-CommLog "📋 Contenido: $($incomingMessage.Data | ConvertTo-Json -Compress)" "DEBUG" $Colors.Info "AE.N.K.I"
            }
            
            # Procesar mensaje y crear respuesta
            $responseType = switch ($incomingMessage.MessageType) {
                "NetworkScanUpdate" { "StatusResponse" }
                "ThreatAlert" { "Command" }
                "StatusUpdate" { "ConfigUpdate" }
                default { "StatusResponse" }
            }
            
            $response = New-AenkiMessage -MessageType $responseType -ResponseTo $incomingMessage.RequestId
            
            # Enviar respuesta
            if (Send-Message -Message $response -FilePath $aenkiToSentinelFile) {
                Write-CommLog "✅ Respuesta enviada: $responseType" "SEND" $Colors.Success "AE.N.K.I"
                
                if ($Verbose) {
                    Write-CommLog "📋 Respuesta: $($response.Data | ConvertTo-Json -Compress)" "DEBUG" $Colors.Info "AE.N.K.I"
                }
            } else {
                Write-CommLog "❌ Error al enviar respuesta" "ERROR" $Colors.Error "AE.N.K.I"
            }
            
            if ($messagesProcessed -ge $MessageCount) {
                Write-CommLog "🏁 Procesados todos los mensajes esperados ($MessageCount)" "INFO" $Colors.Success "AE.N.K.I"
                break
            }
        }
        
        Start-Sleep -Seconds 1
        
        if ($cycle % 30 -eq 0) {
            Write-CommLog "⏳ Esperando mensajes... ($messagesProcessed/$MessageCount procesados)" "WAIT" $Colors.Info "AE.N.K.I"
        }
    }
    
    Write-CommLog "🏁 Simulación de Ae.N.K.I completada" "INFO" $Colors.Success "AE.N.K.I"
}

# Función para test de comunicación bidireccional
function Start-BidirectionalTest {
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-CommLog "                      🔄 BIDIRECTIONAL COMMUNICATION TEST                      " "INFO" $Colors.Header
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    $testResults = @{
        TotalMessages = 0
        SuccessfulMessages = 0
        FailedMessages = 0
        AverageLatency = 0
        TestDuration = 0
        Results = @()
    }
    
    $startTime = Get-Date
    
    for ($i = 1; $i -le $MessageCount; $i++) {
        Write-CommLog "Ejecutando test $i de $MessageCount..." "TEST" $Colors.Info
        
        $testStart = Get-Date
        
        # Sentinel envía mensaje
        $sentinelMessage = New-SentinelMessage -MessageType "NetworkScanUpdate"
        $sentinelFile = ".\orbix_test_sentinel_$i.json"
        
        if (Send-Message -Message $sentinelMessage -FilePath $sentinelFile) {
            Write-CommLog "  🛡️ Sentinel → Mensaje enviado" "SUCCESS" $Colors.Sentinel
            
            # Simular procesamiento por Ae.N.K.I
            Start-Sleep -Milliseconds 500
            
            # Ae.N.K.I responde
            $aenkiMessage = New-AenkiMessage -MessageType "StatusResponse" -ResponseTo $sentinelMessage.RequestId
            $aenkiFile = ".\orbix_test_aenki_$i.json"
            
            if (Send-Message -Message $aenkiMessage -FilePath $aenkiFile) {
                Write-CommLog "  🧠 Ae.N.K.I → Respuesta enviada" "SUCCESS" $Colors.Aenki
                
                # Verificar que Sentinel puede leer la respuesta
                $receivedResponse = Receive-Message -FilePath $aenkiFile
                if ($receivedResponse -and $receivedResponse.ResponseTo -eq $sentinelMessage.RequestId) {
                    $testEnd = Get-Date
                    $latency = ($testEnd - $testStart).TotalMilliseconds
                    
                    Write-CommLog "  ✅ Comunicación bidireccional exitosa ($([math]::Round($latency, 2))ms)" "SUCCESS" $Colors.Success
                    
                    $testResults.SuccessfulMessages++
                    $testResults.AverageLatency += $latency
                    $testResults.Results += [PSCustomObject]@{
                        TestNumber = $i
                        Status = "Success"
                        Latency = $latency
                        SentinelMessage = $sentinelMessage.MessageType
                        AenkiResponse = $aenkiMessage.MessageType
                    }
                } else {
                    Write-CommLog "  ❌ Error en verificación de respuesta" "ERROR" $Colors.Error
                    $testResults.FailedMessages++
                    $testResults.Results += [PSCustomObject]@{
                        TestNumber = $i
                        Status = "Failed"
                        Latency = 0
                        Error = "Response verification failed"
                    }
                }
            } else {
                Write-CommLog "  ❌ Error al enviar respuesta de Ae.N.K.I" "ERROR" $Colors.Error
                $testResults.FailedMessages++
            }
        } else {
            Write-CommLog "  ❌ Error al enviar mensaje de Sentinel" "ERROR" $Colors.Error
            $testResults.FailedMessages++
        }
        
        $testResults.TotalMessages++
        
        # Limpiar archivos de test
        Remove-Item $sentinelFile -Force -ErrorAction SilentlyContinue
        Remove-Item $aenkiFile -Force -ErrorAction SilentlyContinue
        
        if ($i -lt $MessageCount) {
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    
    $endTime = Get-Date
    $testResults.TestDuration = ($endTime - $startTime).TotalSeconds
    
    if ($testResults.SuccessfulMessages -gt 0) {
        $testResults.AverageLatency = $testResults.AverageLatency / $testResults.SuccessfulMessages
    }
    
    # Mostrar resultados
    Write-CommLog "" "INFO" $Colors.Info
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    Write-CommLog "                              📊 RESULTADOS DEL TEST                           " "INFO" $Colors.Header
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    $successRate = if ($testResults.TotalMessages -gt 0) { 
        ($testResults.SuccessfulMessages / $testResults.TotalMessages) * 100 
    } else { 0 }
    
    Write-CommLog "Total de mensajes: $($testResults.TotalMessages)" "INFO" $Colors.Info
    Write-CommLog "Mensajes exitosos: $($testResults.SuccessfulMessages)" "INFO" $Colors.Success
    Write-CommLog "Mensajes fallidos: $($testResults.FailedMessages)" "INFO" $Colors.Error
    Write-CommLog "Tasa de éxito: $([math]::Round($successRate, 1))%" "INFO" $Colors.Info
    Write-CommLog "Latencia promedio: $([math]::Round($testResults.AverageLatency, 2))ms" "INFO" $Colors.Info
    Write-CommLog "Duración del test: $([math]::Round($testResults.TestDuration, 2)) segundos" "INFO" $Colors.Info
    
    $resultColor = if ($successRate -ge 80) { $Colors.Success } elseif ($successRate -ge 60) { $Colors.Warning } else { $Colors.Error }
    $resultStatus = if ($successRate -ge 80) { "🟢 EXCELENTE" } elseif ($successRate -ge 60) { "🟡 ACEPTABLE" } else { "🔴 CRÍTICO" }
    
    Write-CommLog "Calificación: $resultStatus" "OVERALL" $resultColor
    Write-CommLog "═══════════════════════════════════════════════════════════════════════════════" "INFO" $Colors.Header
    
    # Guardar resultados
    try {
        $testResults | ConvertTo-Json -Depth 3 | Out-File -FilePath ".\orbix_communication_test_results.json" -Encoding UTF8
        Write-CommLog "📄 Resultados guardados en: orbix_communication_test_results.json" "INFO" $Colors.Success
    } catch {
        Write-CommLog "❌ No se pudieron guardar los resultados" "ERROR" $Colors.Error
    }
    
    return $testResults
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

if ($StartAsSentinel) {
    Start-SentinelSimulation -MessageCount $MessageCount -IntervalSeconds $IntervalSeconds
} elseif ($StartAsAenki) {
    Start-AenkiSimulation -MessageCount $MessageCount -IntervalSeconds $IntervalSeconds
} elseif ($TestMode) {
    $testResults = Start-BidirectionalTest
    
    # Código de salida basado en los resultados
    $successRate = if ($testResults.TotalMessages -gt 0) { 
        ($testResults.SuccessfulMessages / $testResults.TotalMessages) * 100 
    } else { 0 }
    
    if ($successRate -ge 80) {
        exit 0
    } elseif ($successRate -ge 60) {
        exit 1
    } else {
        exit 2
    }
} else {
    Write-CommLog "Uso: .\orbix_communication_simulator.ps1 [opciones]" "INFO" $Colors.Info
    Write-CommLog "Opciones:" "INFO" $Colors.Info
    Write-CommLog "  -StartAsSentinel      : Simular como Sentinel" "INFO" $Colors.Info
    Write-CommLog "  -StartAsAenki         : Simular como Ae.N.K.I" "INFO" $Colors.Info
    Write-CommLog "  -TestMode             : Ejecutar test bidireccional" "INFO" $Colors.Info
    Write-CommLog "  -MessageCount <n>     : Número de mensajes (default: 5)" "INFO" $Colors.Info
    Write-CommLog "  -IntervalSeconds <n>  : Intervalo entre mensajes (default: 2)" "INFO" $Colors.Info
    Write-CommLog "  -Verbose              : Mostrar detalles de mensajes" "INFO" $Colors.Info
    Write-CommLog "" "INFO" $Colors.Info
    Write-CommLog "Ejemplos:" "INFO" $Colors.Info
    Write-CommLog "  .\orbix_communication_simulator.ps1 -TestMode" "INFO" $Colors.Info
    Write-CommLog "  .\orbix_communication_simulator.ps1 -StartAsSentinel -MessageCount 10" "INFO" $Colors.Info
    Write-CommLog "  .\orbix_communication_simulator.ps1 -StartAsAenki -Verbose" "INFO" $Colors.Info
}
