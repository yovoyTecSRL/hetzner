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
Write-Host ""
Write-Host "=== INFORMACIÓN DEL SERVIDOR ===" -ForegroundColor Cyan
Write-Host "URL Principal: https://sistemasorbix.com" -ForegroundColor Yellow
Write-Host "Dashboard: https://sistemasorbix.com/index.html" -ForegroundColor Yellow
Write-Host "Ultimate: https://sistemasorbix.com/orbix_startpage_ultimate.html" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== INSTRUCCIONES DE SUBIDA ===" -ForegroundColor Cyan
Write-Host "1. Usa FileZilla, WinSCP o similar" -ForegroundColor White
Write-Host "2. Conecta a: sistemasorbix.com" -ForegroundColor White
Write-Host "3. Navega a: /var/www/html/" -ForegroundColor White
Write-Host "4. Sube estos archivos:" -ForegroundColor White
Write-Host "   - index.html (dashboard principal)" -ForegroundColor Green
Write-Host "   - orbix_startpage_ultimate.html (versión completa)" -ForegroundColor Green
Write-Host "5. Establece permisos 644 en ambos archivos" -ForegroundColor White

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETADO ===" -ForegroundColor Green
Write-Host "Dashboard Ultimate listo para usar!" -ForegroundColor Green

# Preguntar si desea iniciar servidor local
$response = Read-Host "¿Deseas iniciar un servidor local para probar? (s/n)"
if ($response -eq "s" -or $response -eq "S") {
    Write-Host "Iniciando servidor local..." -ForegroundColor Yellow
    python -m http.server 8080
}
