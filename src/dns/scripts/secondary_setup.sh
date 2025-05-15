#!/bin/bash
# secondary_setup.sh - Configura servidor DNS secundario con validaciones robustas
set -euo pipefail

# Instalar dependencias necesarias
  echo "[+] Instalando dependencias..."
  apt-get update
  apt-get install -y jq bind9 bind9utils bind9-dnsutils  jq

# Configuración
LOG_FILE="/var/log/dns_secondary_setup.log"
PRIMARY_IP="192.168.20.2"
FORWARD_JSON="/vagrant/config/zone_forward.json"
REVERSE_JSON="/vagrant/config/zone_reverse.json"
REVERSE_IPV6_JSON="/vagrant/config/zone_reverse_ipv6.json"
TSIG_ENV="/vagrant/tsig.env"
TSIG_KEY="tsig-key"
COMMON_FUNCS="/vagrant/scripts/common_functions.sh"

# Iniciar registro
{
  echo "=== Inicio de configuración $(date) ==="

  # Validar archivos requeridos
  for file in "$FORWARD_JSON" "$REVERSE_JSON" "$REVERSE_IPV6_JSON" "$TSIG_ENV" "$COMMON_FUNCS"; do
    if [[ ! -f "$file" ]]; then
      echo "[X] Error: Archivo requerido no encontrado: $file" >&2
      exit 1
    fi
  done

  # Incluir funciones comunes
  source "$COMMON_FUNCS"

  # Obtener valores de zona
  DOMAIN=$(jq -r '.origin' "$FORWARD_JSON" | sed 's/\.$//')
  REVERSE_ORIGIN=$(jq -r '.origin' "$REVERSE_JSON")
  REVERSE_IPV6_ORIGIN=$(jq -r '.origin' "$REVERSE_IPV6_JSON")

  if [[ -z "$DOMAIN" || -z "$REVERSE_ORIGIN" || -z "$REVERSE_IPV6_ORIGIN" ]]; then
    echo "[X] Error: No se pudieron extraer zonas desde los archivos JSON" >&2
    exit 1
  fi

  # Obtener clave TSIG
  TSIG_SECRET=$(grep '^TSIG_SECRET=' "$TSIG_ENV" | cut -d= -f2)
  if [[ -z "$TSIG_SECRET" ]]; then
    echo "[X] Error: Clave TSIG no definida en $TSIG_ENV" >&2
    exit 1
  fi

  echo "[+] Configurando servidor SECUNDARIO para $DOMAIN..."

  

  # Crear archivo de clave TSIG
  echo "[+] Configurando clave TSIG..."
  cat > /etc/bind/tsig.key <<EOF
key "$TSIG_KEY" {
    algorithm hmac-sha256;
    secret "$TSIG_SECRET";
};
EOF

  # Configurar named.conf.local
  echo "[+] Configurando named.conf.local..."
  cat > /etc/bind/named.conf.local <<EOF
include "/etc/bind/tsig.key";

zone "$DOMAIN" {
    type slave;
    masters { $PRIMARY_IP key $TSIG_KEY; };
    file "/var/lib/bind/db.$DOMAIN";
    allow-transfer { none; };
};

zone "$REVERSE_ORIGIN" {
    type slave;
    masters { $PRIMARY_IP key $TSIG_KEY; };
    file "/var/lib/bind/db.reverse";
    allow-transfer { none; };
};

zone "$REVERSE_IPV6_ORIGIN" {
    type slave;
    masters { $PRIMARY_IP key $TSIG_KEY; };
    file "/var/lib/bind/db.reverse.ipv6";
    allow-transfer { none; };
};
EOF

  # Ajustar permisos
  echo "[+] Ajustando permisos..."
  chown bind:bind /etc/bind/tsig.key
  chmod 640 /etc/bind/tsig.key

  # Verificar sintaxis
  echo "[+] Verificando configuración BIND..."
  named-checkconf

  # Reiniciar BIND
  echo "[+] Reiniciando servicio BIND9..."
  systemctl restart bind9

  # Verificar estado de BIND
  check_bind_service || exit 1

  # Verificar transferencia de zonas
  echo "[+] Verificando transferencia de zonas..."
  sleep 5  # Dar tiempo a que BIND complete la transferencia

  for zone in "$DOMAIN" "$REVERSE_ORIGIN" "$REVERSE_IPV6_ORIGIN"; do
    if ! rndc zonestatus "$zone" | grep -q "state: active"; then
      echo "[X] Error: La zona $zone no se transfirió correctamente" >&2
      rndc zonestatus "$zone"
      exit 1
    fi
    echo "[✓] Zona $zone transferida correctamente"
  done

  echo "[✓] Configuración del servidor secundario completada con éxito"
  echo "=== Fin de configuración $(date) ==="

} | tee -a "$LOG_FILE"

exit 0
