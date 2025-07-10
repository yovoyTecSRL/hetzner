# Script de Conexión y Configuración Hetzner
# ORBIX - Hetzner Server Management

param(
    [string]$ServerIP = "sistemasorbix.com",
    [string]$Username = "root",
    [switch]$ConfigureFirewall,
    [switch]$UploadDashboard
)

Write-Host "=== ORBIX Hetzner Connection Manager ===" -ForegroundColor Cyan
Write-Host "Servidor: $ServerIP" -ForegroundColor Yellow

# Función para configurar firewall
function Configure-Firewall {
    Write-Host "Configurando Firewall..." -ForegroundColor Green
    
    $firewallCommands = @(
        "# Permitir SSH (Puerto 22)"
        "ufw allow 22/tcp",
        
        "# Permitir HTTP (Puerto 80)"
        "ufw allow 80/tcp",
        
        "# Permitir HTTPS (Puerto 443)"
        "ufw allow 443/tcp",
        
        "# Permitir puertos personalizados para ORBIX"
        "ufw allow 8080/tcp",
        "ufw allow 8000/tcp",
        "ufw allow 3000/tcp",
        "ufw allow 5000/tcp",
        
        "# Permitir puertos para desarrollo"
        "ufw allow 8888/tcp",
        "ufw allow 9000/tcp",
        
        "# Activar firewall"
        "ufw --force enable",
        
        "# Mostrar estado"
        "ufw status verbose"
    )
    
    Write-Host "Comandos de Firewall a ejecutar:" -ForegroundColor Yellow
    foreach ($cmd in $firewallCommands) {
        if ($cmd.StartsWith("#")) {
            Write-Host $cmd -ForegroundColor Cyan
        } else {
            Write-Host "  $cmd" -ForegroundColor White
        }
    }
    
    Write-Host "`nPara ejecutar estos comandos:" -ForegroundColor Green
    Write-Host "1. Conecta por SSH: ssh $Username@$ServerIP" -ForegroundColor Yellow
    Write-Host "2. Ejecuta cada comando manualmente" -ForegroundColor Yellow
    Write-Host "3. O copia y pega todo el bloque" -ForegroundColor Yellow
}

# Función para subir dashboard
function Upload-Dashboard {
    Write-Host "Preparando archivos para subir..." -ForegroundColor Green
    
    $files = @(
        "index.html",
        "orbix_aenki_dashboard.html"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "✓ $file encontrado" -ForegroundColor Green
        } else {
            Write-Host "✗ $file no encontrado" -ForegroundColor Red
        }
    }
    
    Write-Host "`nComandos SCP para subir archivos:" -ForegroundColor Yellow
    foreach ($file in $files) {
        if (Test-Path $file) {
            Write-Host "scp $file $Username@$ServerIP:/var/www/html/" -ForegroundColor White
        }
    }
}

# Función principal
function Main {
    Write-Host "Opciones disponibles:" -ForegroundColor Green
    Write-Host "1. Conectar por SSH" -ForegroundColor White
    Write-Host "2. Configurar Firewall" -ForegroundColor White
    Write-Host "3. Subir Dashboard" -ForegroundColor White
    Write-Host "4. Verificar conexión" -ForegroundColor White
    
    if ($ConfigureFirewall) {
        Configure-Firewall
    }
    
    if ($UploadDashboard) {
        Upload-Dashboard
    }
    
    Write-Host "`n=== Comandos Útiles ===" -ForegroundColor Cyan
    Write-Host "Conectar SSH: ssh $Username@$ServerIP" -ForegroundColor Yellow
    Write-Host "Verificar web: curl -I http://$ServerIP" -ForegroundColor Yellow
    Write-Host "Ver logs: ssh $Username@$ServerIP 'tail -f /var/log/apache2/access.log'" -ForegroundColor Yellow
}

# Verificar conectividad
Write-Host "Verificando conectividad..." -ForegroundColor Blue
try {
    $response = Test-NetConnection -ComputerName $ServerIP -Port 80 -InformationLevel Quiet
    if ($response) {
        Write-Host "✓ Servidor accesible en puerto 80" -ForegroundColor Green
    } else {
        Write-Host "✗ No se puede conectar al puerto 80" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Error de conectividad: $($_.Exception.Message)" -ForegroundColor Red
}

# Ejecutar función principal
Main
