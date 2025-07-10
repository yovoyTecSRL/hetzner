# Script para subir el dashboard al servidor Hetzner
# ORBIX Ae.N.K.I Dashboard Upload

param(
    [string]$ServerHost = "sistemasorbix.com",
    [string]$Username = "",
    [PSCredential]tring]$Password = $null,
    [string]$DashboardFile = "orbix_aenki_dashboard.html",
    [string]$IndexFile = "index_redirect.html",
    [string]$RemotePath = "/var/www/html/"
)

Write-Host "=== ORBIX Dashboard Upload Script ===" -ForegroundColor Cyan
Write-Host "Preparando para subir el dashboard al servidor..." -ForegroundColor Yellow

# Verificar si el archivo local existe
if (-not (Test-Path $DashboardFile)) {
    Write-Host "Error: No se encontró el archivo dashboard $DashboardFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $IndexFile)) {
    Write-Host "Error: No se encontró el archivo index $IndexFile" -ForegroundColor Red
    exit 1
}

Write-Host "Archivos encontrados:" -ForegroundColor Green
Write-Host "- Dashboard: $DashboardFile" -ForegroundColor Green
Write-Host "- Index: $IndexFile" -ForegroundColor Green

# Verificar conectividad al servidor
Write-Host "Verificando conectividad al servidor $ServerHost..." -ForegroundColor Yellow
$ping = Test-Connection -ComputerName $ServerHost -Count 2 -Quiet
if ($ping) {
    Write-Host "Servidor accesible" -ForegroundColor Green
} else {
    Write-Host "Error: No se puede conectar al servidor" -ForegroundColor Red
    exit 1
}

# Instrucciones para subir manualmente
Write-Host "=== INSTRUCCIONES DE SUBIDA MANUAL ===" -ForegroundColor Cyan
Write-Host "1. Usa un cliente FTP/SFTP como FileZilla o WinSCP" -ForegroundColor Yellow
Write-Host "2. Conecta al servidor: $ServerHost" -ForegroundColor Yellow
Write-Host "3. Navega al directorio web: $RemotePath" -ForegroundColor Yellow
Write-Host "4. Sube los archivos:" -ForegroundColor Yellow
Write-Host "   - $DashboardFile" -ForegroundColor White
Write-Host "   - $IndexFile -> renombrar a index.html" -ForegroundColor White
Write-Host "5. Asegúrate de que los archivos tengan permisos de lectura (644)" -ForegroundColor Yellow

# Alternativa usando curl (si está disponible)
Write-Host "=== ALTERNATIVA CON CURL ===" -ForegroundColor Cyan
Write-Host "Si tienes curl instalado, puedes usar este comando:" -ForegroundColor Yellow
Write-Host "curl -T $LocalFile ftp://$ServerHost$RemotePath --user username:password" -ForegroundColor White

# Verificar si curl está disponible
try {
    $curlVersion = & curl.exe --version 2>$null
    if ($curlVersion) {
        Write-Host "Curl disponible en el sistema" -ForegroundColor Green
        
        if ($Username -and $Password) {
            Write-Host "Intentando subir archivos con curl..." -ForegroundColor Yellow
            $credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
            $plainPassword = $credential.GetNetworkCredential().Password
            
            Write-Host "Subiendo archivo dashboard..." -ForegroundColor Gray
            & curl.exe -T $DashboardFile "ftp://$ServerHost$RemotePath" --user "$Username`:$plainPassword"
            
            Write-Host "Subiendo archivo index..." -ForegroundColor Gray
            & curl.exe -T $IndexFile "ftp://$ServerHost$RemotePath`index.html" --user "$Username`:$plainPassword"
        } else {
            Write-Host "Proporciona credenciales con -Username y -Password para usar curl" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Curl no disponible, usa método manual" -ForegroundColor Yellow
}

Write-Host "=== FIN DEL SCRIPT ===" -ForegroundColor Cyan
