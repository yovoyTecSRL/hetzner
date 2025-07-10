#!/bin/bash
# Script para reparar el dashboard ORBIX en sistemasorbix.com

echo "=== REPARACIÓN DEL DASHBOARD ORBIX AE.N.K.I ==="
echo "Preparando archivos para subir al servidor..."

# Archivo a subir
DASHBOARD_FILE="orbix_aenki_dashboard_simple.html"
SERVER_FILE="orbix_aenki_dashboard.html"
SERVER_HOST="sistemasorbix.com"

# Verificar si el archivo existe
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ Error: No se encontró el archivo $DASHBOARD_FILE"
    exit 1
fi

echo "✅ Archivo encontrado: $DASHBOARD_FILE"

# Mostrar información del archivo
echo "📊 Información del archivo:"
ls -lh "$DASHBOARD_FILE"

# Verificar conectividad
echo "🌐 Verificando conectividad al servidor..."
if ping -c 2 "$SERVER_HOST" > /dev/null 2>&1; then
    echo "✅ Servidor accesible"
else
    echo "❌ Error: No se puede conectar al servidor"
    exit 1
fi

echo ""
echo "=== OPCIONES DE SUBIDA ==="
echo "1. Subir vía SCP (requiere SSH)"
echo "2. Subir vía FTP"
echo "3. Mostrar instrucciones manuales"
echo ""

read -p "Selecciona una opción (1-3): " option

case $option in
    1)
        echo "📤 Subiendo vía SCP..."
        read -p "Usuario SSH: " ssh_user
        scp "$DASHBOARD_FILE" "$ssh_user@$SERVER_HOST:/var/www/html/$SERVER_FILE"
        if [ $? -eq 0 ]; then
            echo "✅ Archivo subido exitosamente vía SCP"
        else
            echo "❌ Error en la subida vía SCP"
        fi
        ;;
    2)
        echo "📤 Subiendo vía FTP..."
        read -p "Usuario FTP: " ftp_user
        read -s -p "Contraseña FTP: " ftp_pass
        echo ""
        
        # Crear script FTP temporal
        cat > /tmp/ftp_script << EOF
open $SERVER_HOST
user $ftp_user $ftp_pass
binary
put $DASHBOARD_FILE $SERVER_FILE
quit
EOF
        
        ftp -n < /tmp/ftp_script
        rm /tmp/ftp_script
        
        if [ $? -eq 0 ]; then
            echo "✅ Archivo subido exitosamente vía FTP"
        else
            echo "❌ Error en la subida vía FTP"
        fi
        ;;
    3)
        echo "=== INSTRUCCIONES MANUALES ==="
        echo "1. Usa un cliente FTP como FileZilla o WinSCP"
        echo "2. Conecta al servidor: $SERVER_HOST"
        echo "3. Navega al directorio: /var/www/html/"
        echo "4. Sube el archivo: $DASHBOARD_FILE"
        echo "5. Renómbralo a: $SERVER_FILE"
        echo "6. Asegúrate de que tenga permisos 644"
        echo ""
        echo "Alternativamente, puedes usar curl:"
        echo "curl -T $DASHBOARD_FILE ftp://$SERVER_HOST/html/ --user usuario:contraseña"
        ;;
    *)
        echo "❌ Opción no válida"
        exit 1
        ;;
esac

echo ""
echo "🔍 Verificando la subida..."
echo "Intentando acceder a: https://$SERVER_HOST/$SERVER_FILE"

# Verificar que el archivo esté disponible
if curl -s -I "https://$SERVER_HOST/$SERVER_FILE" | grep -q "200 OK"; then
    echo "✅ Dashboard disponible en: https://$SERVER_HOST/$SERVER_FILE"
else
    echo "⚠️  El archivo podría no estar disponible aún. Verifica la subida."
fi

echo ""
echo "=== PROCESO COMPLETADO ==="
echo "El dashboard debería estar disponible en:"
echo "🌐 https://$SERVER_HOST/$SERVER_FILE"
