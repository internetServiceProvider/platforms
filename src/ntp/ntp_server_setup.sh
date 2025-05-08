#!/bin/bash

set -euo pipefail

echo "[+] Configurando zona horaria de Colombia..."
timedatectl set-timezone America/Bogota

echo "[+] Instalando NTP..."
apt-get update -qq
apt-get install -y ntp ufw net-tools ntpstat

echo "[+] Aplicando configuración personalizada de NTP..."
cat > /etc/ntp.conf << 'NTPEOF'
driftfile /var/lib/ntp/ntp.drift

# Servidores principales para Colombia (con redundancia regional)
server 0.co.pool.ntp.org iburst
server 1.south-america.pool.ntp.org iburst
server 0.south-america.pool.ntp.org iburst

# Servidores de respaldo globales
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst

# Fuente local como último recurso (stratum 10)
server 127.127.1.0
fudge 127.127.1.0 stratum 10

# Restricciones de seguridad
restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1

# Permitir clientes locales
restrict 192.168.20.0 mask 255.255.255.0 nomodify notrap
restrict 192.168.10.0 mask 255.255.255.0 nomodify notrap

# Optimización para redes con poca estabilidad
tinker panic 0
NTPEOF

echo "[+] Reiniciando y habilitando el servicio NTP..."
systemctl restart ntp
systemctl enable ntp

echo "[+] Permitendo el puerto 123/udp en el firewall..."
ufw allow 123/udp || true

echo "[+] Verificando sincronización NTP..."
sleep 5
ntpq -p || echo "[-] ntpq no está respondiendo"
ntpstat || echo "[-] ntpstat falló"
timedatectl
