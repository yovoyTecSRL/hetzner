# Comandos de Firewall para Hetzner
# Ejecutar estos comandos después de conectar por SSH

# ======================================
# CONFIGURACIÓN DE FIREWALL UFW
# ======================================

# Resetear firewall (opcional)
ufw --force reset

# Permitir SSH (CRÍTICO - no bloquees tu acceso)
ufw allow 22/tcp

# Permitir HTTP y HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Puertos para desarrollo web y aplicaciones
ufw allow 8000/tcp
ufw allow 8080/tcp
ufw allow 3000/tcp
ufw allow 5000/tcp

# Puertos para servicios adicionales
ufw allow 8888/tcp
ufw allow 9000/tcp
ufw allow 4000/tcp

# Permitir ping (opcional)
ufw allow from any to any port 22 proto tcp

# Reglas específicas para ORBIX
ufw allow from any to any port 8080 proto tcp comment 'ORBIX Dashboard'
ufw allow from any to any port 3000 proto tcp comment 'ORBIX API'

# Activar firewall
ufw --force enable

# Verificar estado
ufw status verbose
ufw status numbered

# ======================================
# COMANDOS ADICIONALES ÚTILES
# ======================================

# Ver logs del firewall
tail -f /var/log/ufw.log

# Verificar puertos abiertos
netstat -tuln

# Verificar servicios activos
systemctl list-units --type=service --state=active

# Reiniciar servicios web
systemctl restart apache2
systemctl restart nginx

# Verificar estado de servicios
systemctl status apache2
systemctl status nginx

# ======================================
# CONFIGURACIÓN APACHE/NGINX
# ======================================

# Si usas Apache, editar configuración
# nano /etc/apache2/sites-available/000-default.conf

# Si usas Nginx, editar configuración
# nano /etc/nginx/sites-available/default

# Crear directorio para ORBIX si no existe
mkdir -p /var/www/html/orbix

# Cambiar permisos
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# ======================================
# SCRIPT DE VERIFICACIÓN
# ======================================

echo "=== VERIFICACIÓN DEL SISTEMA ==="
echo "Firewall Status:"
ufw status verbose
echo ""
echo "Puertos abiertos:"
netstat -tuln | grep LISTEN
echo ""
echo "Servicios web activos:"
systemctl status apache2 --no-pager
systemctl status nginx --no-pager
echo ""
echo "Contenido web:"
ls -la /var/www/html/
