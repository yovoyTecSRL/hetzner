# Script PowerShell para reparar el dashboard ORBIX en sistemasorbix.com

Write-Host "=== REPARACIÓN DEL DASHBOARD ORBIX AE.N.K.I ===" -ForegroundColor Cyan
Write-Host "Preparando archivos para subir al servidor..." -ForegroundColor Yellow

# Configuración
$DashboardFile = "orbix_aenki_dashboard_simple.html"
$ServerFile = "orbix_aenki_dashboard.html"
$ServerHost = "sistemasorbix.com"

# Verificar si el archivo existe
if (-not (Test-Path $DashboardFile)) {
    Write-Host "❌ Error: No se encontró el archivo $DashboardFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo encontrado: $DashboardFile" -ForegroundColor Green

# Mostrar información del archivo
$FileInfo = Get-Item $DashboardFile
Write-Host "📊 Información del archivo:" -ForegroundColor Cyan
Write-Host "   Tamaño: $($FileInfo.Length) bytes" -ForegroundColor White
Write-Host "   Modificado: $($FileInfo.LastWriteTime)" -ForegroundColor White

# Verificar conectividad
Write-Host "🌐 Verificando conectividad al servidor..." -ForegroundColor Yellow
$PingResult = Test-Connection -ComputerName $ServerHost -Count 2 -Quiet
if ($PingResult) {
    Write-Host "✅ Servidor accesible" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se puede conectar al servidor" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== OPCIONES DE SUBIDA ===" -ForegroundColor Cyan
Write-Host "1. Subir vía SFTP (requiere WinSCP o similar)" -ForegroundColor White
Write-Host "2. Subir vía FTP con PowerShell" -ForegroundColor White
Write-Host "3. Mostrar instrucciones manuales" -ForegroundColor White
Write-Host "4. Crear archivo .bat para subida automática" -ForegroundColor White
Write-Host ""

$Option = Read-Host "Selecciona una opción (1-4)"

switch ($Option) {
    "1" {
        Write-Host "📤 Preparando subida vía SFTP..." -ForegroundColor Yellow
        Write-Host "Para usar SFTP, necesitas instalar WinSCP o usar un cliente similar." -ForegroundColor Yellow
        Write-Host "Comando WinSCP:" -ForegroundColor Cyan
        Write-Host "winscp.com /command `"open sftp://usuario@$ServerHost`" `"put $DashboardFile /var/www/html/$ServerFile`" `"exit`"" -ForegroundColor White
    }
    
    "2" {
        Write-Host "📤 Subiendo vía FTP..." -ForegroundColor Yellow
        $FtpUser = Read-Host "Usuario FTP"
        $FtpPass = Read-Host "Contraseña FTP" -AsSecureString
        $FtpPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($FtpPass))
        
        try {
            # Crear solicitud FTP
            $FtpRequest = [System.Net.FtpWebRequest]::Create("ftp://$ServerHost/$ServerFile")
            $FtpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
            $FtpRequest.Credentials = New-Object System.Net.NetworkCredential($FtpUser, $FtpPassPlain)
            $FtpRequest.UseBinary = $true
            
            # Leer el archivo
            $FileContent = [System.IO.File]::ReadAllBytes($DashboardFile)
            $FtpRequest.ContentLength = $FileContent.Length
            
            # Subir el archivo
            $RequestStream = $FtpRequest.GetRequestStream()
            $RequestStream.Write($FileContent, 0, $FileContent.Length)
            $RequestStream.Close()
            
            $Response = $FtpRequest.GetResponse()
            Write-Host "✅ Archivo subido exitosamente vía FTP" -ForegroundColor Green
            $Response.Close()
        }
        catch {
            Write-Host "❌ Error en la subida vía FTP: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "3" {
        Write-Host "=== INSTRUCCIONES MANUALES ===" -ForegroundColor Cyan
        Write-Host "1. Usa un cliente FTP como FileZilla o WinSCP" -ForegroundColor White
        Write-Host "2. Conecta al servidor: $ServerHost" -ForegroundColor White
        Write-Host "3. Navega al directorio: /var/www/html/" -ForegroundColor White
        Write-Host "4. Sube el archivo: $DashboardFile" -ForegroundColor White
        Write-Host "5. Renómbralo a: $ServerFile" -ForegroundColor White
        Write-Host "6. Asegúrate de que tenga permisos 644" -ForegroundColor White
        Write-Host ""
        Write-Host "Alternativamente, puedes usar curl:" -ForegroundColor Yellow
        Write-Host "curl -T $DashboardFile ftp://$ServerHost/html/ --user usuario:contraseña" -ForegroundColor White
    }
    
    "4" {
        Write-Host "📝 Creando archivo .bat para subida automática..." -ForegroundColor Yellow
        $BatchContent = @"
@echo off
echo === SUBIDA AUTOMÁTICA DEL DASHBOARD ORBIX ===
echo Subiendo archivo al servidor...

REM Usar curl para subir el archivo
curl -T "$DashboardFile" ftp://$ServerHost/html/$ServerFile --user %1:%2

if %errorlevel% == 0 (
    echo ✅ Archivo subido exitosamente
    echo 🌐 Dashboard disponible en: https://$ServerHost/$ServerFile
) else (
    echo ❌ Error en la subida
)

pause
"@
        $BatchContent | Out-File -FilePath "upload_dashboard.bat" -Encoding ASCII
        Write-Host "✅ Archivo upload_dashboard.bat creado" -ForegroundColor Green
        Write-Host "Uso: upload_dashboard.bat usuario contraseña" -ForegroundColor Yellow
    }
    
    default {
        Write-Host "❌ Opción no válida" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🔍 Verificando la disponibilidad del dashboard..." -ForegroundColor Yellow
$DashboardUrl = "https://$ServerHost/$ServerFile"
Write-Host "Intentando acceder a: $DashboardUrl" -ForegroundColor White

try {
    $WebRequest = Invoke-WebRequest -Uri $DashboardUrl -Method Head -ErrorAction Stop
    if ($WebRequest.StatusCode -eq 200) {
        Write-Host "✅ Dashboard disponible en: $DashboardUrl" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  El archivo podría no estar disponible aún. Verifica la subida." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== PROCESO COMPLETADO ===" -ForegroundColor Cyan
Write-Host "El dashboard debería estar disponible en:" -ForegroundColor White
Write-Host "🌐 $DashboardUrl" -ForegroundColor Green

# Abrir el dashboard en el navegador
$OpenBrowser = Read-Host "¿Deseas abrir el dashboard en el navegador? (s/n)"
if ($OpenBrowser -eq "s" -or $OpenBrowser -eq "S") {
    Start-Process $DashboardUrl
}
