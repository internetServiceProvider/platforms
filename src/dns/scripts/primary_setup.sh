#!/bin/bash
# primary_setup.sh
set -e

# Cargar funciones comunes
echo "[+] Cargando funciones comunes..."
source /vagrant/scripts/common_functions.sh

echo "[+] Instalando dependencias..."
sudo apt update
sudo apt install -y jq bind9 bind9utils bind9-dnsutils

# Variables
ZONE_DIR="/etc/bind/zones"
FORWARD_JSON="/vagrant/config/zone_forward.json"
REVERSE_JSON="/vagrant/config/zone_reverse.json"
REVERSE_IPV6_JSON="/vagrant/config/zone_reverse_ipv6.json"
DOMAIN=$(jq -r '.origin' "$FORWARD_JSON" | sed 's/\.$//')
TSIG_KEY="tsig-key"
TSIG_SECRET=$(openssl rand -base64 32 | tr -d '\n')

# Validaciones básicas
[ -z "$DOMAIN" ] && echo "[X] No se pudo extraer el dominio del JSON." && exit 1
sudo mkdir -p "$ZONE_DIR"

echo "[+] Configurando servidor PRIMARIO para $DOMAIN..."

# 1. Configurar clave TSIG
cat > /etc/bind/tsig.key <<EOF
key "$TSIG_KEY" {
    algorithm hmac-sha256;
    secret "$TSIG_SECRET";
};
EOF

# 2. Generar archivos de zona desde JSON
configure_zone "forward" "$FORWARD_JSON" "$ZONE_DIR/db.$DOMAIN" "$DOMAIN"
configure_zone "reverse" "$REVERSE_JSON" "$ZONE_DIR/db.reverse" "$DOMAIN"
configure_zone "reverse_ipv6" "$REVERSE_IPV6_JSON" "$ZONE_DIR/db.reverse.ipv6" "$DOMAIN"

# 3. Configurar DNSSEC (opcional si usas dnssec-policy; puedes comentar esto si solo usas políticas)
# setup_dnssec "$ZONE_DIR/db.$DOMAIN" "$DOMAIN"

# 4. Configurar named.conf.local con dnssec-policy
cat > /etc/bind/named.conf.local <<EOF
include "/etc/bind/tsig.key";

zone "$DOMAIN" {
    type master;
    file "$ZONE_DIR/db.$DOMAIN";
    allow-transfer { key $TSIG_KEY; };
    inline-signing yes;
    dnssec-policy "default";
};

zone "$(jq -r '.origin' "$REVERSE_JSON")" {
    type master;
    file "$ZONE_DIR/db.reverse";
    allow-transfer { key $TSIG_KEY; };
};

zone "$(jq -r '.origin' "$REVERSE_IPV6_JSON")" {
    type master;
    file "$ZONE_DIR/db.reverse.ipv6";
    allow-transfer { key $TSIG_KEY; };
};
EOF

# 5. Guardar clave TSIG para el secundario
echo "TSIG_SECRET=$TSIG_SECRET" > /vagrant/tsig.env

# 6. Permisos correctos
sudo chown -R bind:bind "$ZONE_DIR"
sudo rndc reload

echo "[✓] Configuración del servidor primario completada. Clave TSIG: $TSIG_SECRET"
