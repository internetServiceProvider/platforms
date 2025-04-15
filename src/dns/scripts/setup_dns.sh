#!/bin/bash

set -e

echo "[+] Instalando BIND9 y herramientas..."
apt update
apt install -y bind9 bind9utils bind9-dnsutils jq

echo "[+] Configurando zonas..."
FORWARD_JSON="/vagrant/config/zone_forward.json"
REVERSE_JSON="/vagrant/config/zone_reverse.json"
REVERSE_IPV6_JSON="/vagrant/config/zone_reverse_ipv6.json"
ZONE_DIR="/etc/bind/zones"
mkdir -p "$ZONE_DIR"

DOMAIN=$(jq -r '.origin' $FORWARD_JSON)
DOMAIN_CLEAN=${DOMAIN%?}
FORWARD_FILE="$ZONE_DIR/db.${DOMAIN_CLEAN}"
REVERSE_FILE="$ZONE_DIR/db.reverse"
REVERSE_IPV6_FILE="$ZONE_DIR/db.reverse.ipv6"

# 1. Crear archivo de zona directa con IPv4 + IPv6
cat > "$FORWARD_FILE" <<EOF
\$TTL 3600
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        2025041401 ; Serial
        7200       ; Refresh
        3600       ; Retry
        1209600    ; Expire
        86400 )    ; Minimum TTL
    IN  NS  ns1.$DOMAIN.
EOF

jq -c '.records[]' "$FORWARD_JSON" | while read -r record; do
  name=$(echo "$record" | jq -r '.name')
  type=$(echo "$record" | jq -r '.type')
  value=$(echo "$record" | jq -r '.value')
  echo "$name IN $type $value" >> "$FORWARD_FILE"
done

# 2. Crear zona inversa IPv4
cat > "$REVERSE_FILE" <<EOF
\$TTL 3600
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        2025041401 ; Serial
        7200       ; Refresh
        3600       ; Retry
        1209600    ; Expire
        86400 )    ; Minimum TTL
    IN  NS  ns1.$DOMAIN.
EOF

jq -c '.records[]' "$REVERSE_JSON" | while read -r record; do
  name=$(echo "$record" | jq -r '.name')
  value=$(echo "$record" | jq -r '.value')
  echo "$name IN PTR $value" >> "$REVERSE_FILE"
done

# 3. Crear zona inversa IPv6
cat > "$REVERSE_IPV6_FILE" <<EOF
\$TTL 3600
@   IN  SOA ns1.$DOMAIN. admin.$DOMAIN. (
        2025041401 ; Serial
        7200       ; Refresh
        3600       ; Retry
        1209600    ; Expire
        86400 )    ; Minimum TTL
    IN  NS  ns1.$DOMAIN.
EOF

jq -c '.records[]' "$REVERSE_IPV6_JSON" | while read -r record; do
  name=$(echo "$record" | jq -r '.name')
  value=$(echo "$record" | jq -r '.value')
  echo "$name IN PTR $value" >> "$REVERSE_IPV6_FILE"
done

# 4. DNSSEC: generar claves y firmar
echo "[+] Generando claves DNSSEC..."
cd "$ZONE_DIR"
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE $DOMAIN
dnssec-keygen -f KSK -a RSASHA256 -b 2048 -n ZONE $DOMAIN

echo "[+] Firmando zona..."
cat "$FORWARD_FILE" K$DOMAIN*.key > unsigned.zone
dnssec-signzone -A -o $DOMAIN -N increment -t unsigned.zone
mv unsigned.zone.signed "$FORWARD_FILE.signed"

# 5. named.conf.local
cat > /etc/bind/named.conf.local <<EOF
zone "$DOMAIN" {
    type master;
    file "$FORWARD_FILE.signed";
    auto-dnssec maintain;
    inline-signing yes;
};

zone "$(jq -r '.origin' $REVERSE_JSON)" {
    type master;
    file "$REVERSE_FILE";
};

zone "$(jq -r '.origin' $REVERSE_IPV6_JSON)" {
    type master;
    file "$REVERSE_IPV6_FILE";
};
EOF

# 6. named.conf.options
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    dnssec-validation auto;
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
    recursion yes;
};
EOF

echo "[+] Reiniciando BIND9..."
systemctl restart named
systemctl enable named

echo "[✓] DNS con DNSSEC e IPv6 configurado correctamente."
