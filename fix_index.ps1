# Script para reemplazar el index.html actual con el dashboard
# ORBIX Ae.N.K.I - Index Fix

Write-Host "=== ORBIX Index Fix Script ===" -ForegroundColor Cyan
Write-Host "Reparando el archivo index.html para que apunte al dashboard..." -ForegroundColor Yellow

# Verificar archivos necesarios
$dashboardFile = "orbix_aenki_dashboard.html"
$indexRedirectFile = "index_redirect.html"

if (-not (Test-Path $dashboardFile)) {
    Write-Host "Error: No se encontró $dashboardFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $indexRedirectFile)) {
    Write-Host "Error: No se encontró $indexRedirectFile" -ForegroundColor Red
    exit 1
}

# Crear backup del index actual
if (Test-Path "index.html") {
    Copy-Item "index.html" "index_backup.html" -Force
    Write-Host "Backup creado: index_backup.html" -ForegroundColor Green
}

# Copiar el archivo de redirección como index.html
Copy-Item $indexRedirectFile "index.html" -Force
Write-Host "Archivo index.html actualizado con redirección al dashboard" -ForegroundColor Green

# Verificar que el servidor local funcione
Write-Host "Iniciando servidor local para verificar..." -ForegroundColor Yellow
$serverJob = Start-Job -ScriptBlock {
    param($port)
    try {
        $http = [System.Net.HttpListener]::new()
        $http.Prefixes.Add("http://localhost:$port/")
        $http.Start()
        
        while ($http.IsListening) {
            $context = $http.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $requestedFile = $request.Url.AbsolutePath.TrimStart('/')
            if ($requestedFile -eq "" -or $requestedFile -eq "/") {
                $requestedFile = "index.html"
            }
            
            if (Test-Path $requestedFile) {
                $content = [System.IO.File]::ReadAllBytes($requestedFile)
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            } else {
                $response.StatusCode = 404
                $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - File not found")
                $response.ContentLength64 = $notFound.Length
                $response.OutputStream.Write($notFound, 0, $notFound.Length)
            }
            
            $response.Close()
        }
    } catch {
        Write-Error "Error en servidor: $_"
    }
} -ArgumentList 8080

Start-Sleep -Seconds 2

Write-Host "Servidor local iniciado en http://localhost:8080" -ForegroundColor Green
Write-Host "Abriendo navegador para verificar..." -ForegroundColor Yellow

# Abrir navegador
Start-Process "http://localhost:8080"

Write-Host "Presiona Enter para detener el servidor y continuar..." -ForegroundColor Yellow
Read-Host

# Detener servidor
Stop-Job $serverJob -Force
Remove-Job $serverJob -Force

Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "✅ Archivo index.html actualizado" -ForegroundColor Green
Write-Host "✅ Redirección al dashboard configurada" -ForegroundColor Green
Write-Host "✅ Servidor local verificado" -ForegroundColor Green
Write-Host ""
Write-Host "Para subir al servidor Hetzner:" -ForegroundColor Yellow
Write-Host "1. Usa FileZilla o WinSCP" -ForegroundColor White
Write-Host "2. Conecta a sistemasorbix.com" -ForegroundColor White
Write-Host "3. Sube index.html y $dashboardFile" -ForegroundColor White
Write-Host "4. Verifica https://sistemasorbix.com" -ForegroundColor White
Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Cyan
