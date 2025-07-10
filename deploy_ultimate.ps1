# Script para actualizar el dashboard ORBIX Ultimate
# Actualización del sistema principal

Write-Host "=== ORBIX Ae.N.K.I - Ultimate Dashboard Deployment ===" -ForegroundColor Cyan
Write-Host "Preparando deployment del dashboard ultimate..." -ForegroundColor Yellow

# Verificar archivos
$ultimateFile = "orbix_startpage_ultimate.html"
$indexFile = "index.html"

if (Test-Path $ultimateFile) {
    Write-Host "✅ Dashboard Ultimate encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ Error: No se encontró $ultimateFile" -ForegroundColor Red
    exit 1
}

# Crear backup del index actual
if (Test-Path $indexFile) {
    $backupName = "index_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Copy-Item $indexFile $backupName
    Write-Host "📋 Backup creado: $backupName" -ForegroundColor Blue
}

# Copiar el dashboard ultimate como index
Copy-Item $ultimateFile $indexFile -Force
Write-Host "🚀 Dashboard Ultimate activado como página principal" -ForegroundColor Green

# Mostrar información del servidor
Write-Host "`n=== INFORMACIÓN DEL SERVIDOR ===" -ForegroundColor Cyan
Write-Host "URL Principal: https://sistemasorbix.com" -ForegroundColor Yellow
Write-Host "Dashboard: https://sistemasorbix.com/index.html" -ForegroundColor Yellow
Write-Host "Ultimate: https://sistemasorbix.com/orbix_startpage_ultimate.html" -ForegroundColor Yellow

Write-Host "`n=== INSTRUCCIONES DE SUBIDA ===" -ForegroundColor Cyan
Write-Host "1. Usa FileZilla, WinSCP o similar" -ForegroundColor White
Write-Host "2. Conecta a: sistemasorbix.com" -ForegroundColor White
Write-Host "3. Navega a: /var/www/html/" -ForegroundColor White
Write-Host "4. Sube estos archivos:" -ForegroundColor White
Write-Host "   - index.html (dashboard principal)" -ForegroundColor Green
Write-Host "   - orbix_startpage_ultimate.html (versión completa)" -ForegroundColor Green
Write-Host "5. Establece permisos 644 en ambos archivos" -ForegroundColor White

# Verificar servidor local
Write-Host "`n=== SERVIDOR LOCAL ===" -ForegroundColor Cyan
Write-Host "Iniciando servidor local para pruebas..." -ForegroundColor Yellow

try {
    $port = 8080
    $url = "http://localhost:$port"
    
    Write-Host "Servidor iniciado en: $url" -ForegroundColor Green
    Write-Host "Presiona Ctrl+C para detener el servidor" -ForegroundColor Yellow
    
    # Abrir en navegador
    Start-Process $url
    
    # Iniciar servidor HTTP simple
    python -m http.server $port 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Python no disponible, intentando con PowerShell..." -ForegroundColor Yellow
        
        # Servidor HTTP con PowerShell
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add("http://localhost:$port/")
        $listener.Start()
        Write-Host "Servidor HTTP iniciado en puerto $port" -ForegroundColor Green
        
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $localPath = $request.Url.LocalPath
            if ($localPath -eq "/") {
                $localPath = "/index.html"
            }
            
            $filePath = Join-Path $PWD $localPath.TrimStart('/')
            
            if (Test-Path $filePath) {
                $content = Get-Content $filePath -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentLength64 = $buffer.Length
                $response.ContentType = "text/html; charset=utf-8"
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            } else {
                $response.StatusCode = 404
                $notFound = "<html><body><h1>404 - Not Found</h1></body></html>"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($notFound)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        }
    }
} catch {
    Write-Host "Error al iniciar servidor: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DEPLOYMENT COMPLETADO ===" -ForegroundColor Green
Write-Host "Dashboard Ultimate listo para usar!" -ForegroundColor Green
