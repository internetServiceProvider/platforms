#!/bin/bash

# Configurar zona horaria de Colombia
timedatectl set-timezone America/Bogota

# Instalar y configurar NTP como cliente
apt-get update
apt-get install -y ntp ntpstat

# Configuración NTP
cat > /etc/ntp.conf << 'NTPEOF'
driftfile /var/lib/ntp/ntp.drift
# Servidor NTP local
server 192.168.88.10 iburst prefer
# Restricciones
restrict 127.0.0.1
restrict ::1
restrict default nomodify notrap nopeer noquery
NTPEOF

systemctl restart ntp
timedatectl set-ntp true

# Verificar sincronización
sleep 5
ntpq -p
ntpstat || true
timedatectl