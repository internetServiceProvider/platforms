#!/bin/bash
# common_functions.sh - Funciones mejoradas con manejo de errores

# Configura zonas DNS basadas en JSON
configure_zone() {
  local ZONE_TYPE=$1
  local JSON_FILE=$2
  local OUTPUT_FILE=$3
  local DOMAIN=$4

  # Validaciones
  if [[ -z "$ZONE_TYPE" || -z "$JSON_FILE" || -z "$OUTPUT_FILE" || -z "$DOMAIN" ]]; then
    echo "[X] Error: Faltan parámetros en configure_zone()" >&2
    return 1
  fi

  if [[ ! -f "$JSON_FILE" ]]; then
    echo "[X] Error: Archivo JSON $JSON_FILE no encontrado" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "[X] Error: jq no está instalado" >&2
    return 1
  fi

  echo "[+] Configurando zona $ZONE_TYPE en $OUTPUT_FILE..."

  # Crear directorio si no existe
  mkdir -p "$(dirname "$OUTPUT_FILE")" || {
    echo "[X] Error: No se pudo crear directorio para $OUTPUT_FILE" >&2
    return 1
  }

  # Plantilla común para SOA y NS
  cat > "$OUTPUT_FILE" <<EOF
\$TTL 3600
@   IN  SOA ns1.${DOMAIN} admin.${DOMAIN} (
        $(date +%Y%m%d%H) ; Serial
        7200       ; Refresh
        3600       ; Retry
        1209600    ; Expire
        3600 )     ; Minimum TTL
    IN  NS  ns1.${DOMAIN}.
    IN  NS  ns2.${DOMAIN}.
EOF

  # Agregar registros específicos
  case "$ZONE_TYPE" in
    "forward")
      if ! jq -c '.records[]' "$JSON_FILE" | while read -r record; do
        echo "$(jq -r '.name + " IN " + .type + " " + .value' <<< "$record")" || exit 1
      done >> "$OUTPUT_FILE"; then
        echo "[X] Error procesando registros forward" >&2
        return 1
      fi
      ;;
    "reverse"|"reverse_ipv6")
      if ! jq -c '.records[]' "$JSON_FILE" | while read -r record; do
        echo "$(jq -r '.name + " IN PTR " + .value' <<< "$record")" || exit 1
      done >> "$OUTPUT_FILE"; then
        echo "[X] Error procesando registros reverse" >&2
        return 1
      fi
      ;;
    *)
      echo "[X] Error: Tipo de zona desconocido: $ZONE_TYPE" >&2
      return 1
      ;;
  esac

  echo "[✓] Zona $ZONE_TYPE configurada correctamente en $OUTPUT_FILE"
  return 0
}

# Configura DNSSEC para una zona
setup_dnssec() {
  local ZONE_FILE=$1
  local DOMAIN=$2

  # Validaciones
  if [[ -z "$ZONE_FILE" || -z "$DOMAIN" ]]; then
    echo "[X] Error: Faltan parámetros en setup_dnssec()" >&2
    return 1
  fi

  if [[ ! -f "$ZONE_FILE" ]]; then
    echo "[X] Error: Archivo de zona $ZONE_FILE no encontrado" >&2
    return 1
  fi

  echo "[+] Generando claves DNSSEC para $DOMAIN..."
  cd "$(dirname "$ZONE_FILE")" || {
    echo "[X] Error: No se pudo cambiar al directorio $(dirname "$ZONE_FILE")" >&2
    return 1
  }

  if ! dnssec-keygen -a RSASHA256 -b 2048 -n ZONE "$DOMAIN"; then
    echo "[X] Error generando clave ZSK" >&2
    return 1
  fi

  if ! dnssec-keygen -f KSK -a RSASHA256 -b 2048 -n ZONE "$DOMAIN"; then
    echo "[X] Error generando clave KSK" >&2
    return 1
  fi

  echo "[+] Firmando zona..."
  cat "$ZONE_FILE" K$DOMAIN*.key > unsigned.zone || {
    echo "[X] Error creando zona sin firmar" >&2
    return 1
  }

  if ! dnssec-signzone -A -o "$DOMAIN" -N increment -t unsigned.zone; then
    echo "[X] Error firmando zona" >&2
    return 1
  fi

   mv unsigned.zone.signed "${ZONE_FILE}.signed" || {
    echo "[X] Error moviendo zona firmada" >&2
    return 1
   }
  
  echo "[✓] DNSSEC configurado correctamente para $DOMAIN"
  return 0
}

# Función para verificar servicio BIND
check_bind_service() {
  echo "[+] Verificando estado de BIND9..."
  if ! systemctl is-active --quiet bind9; then
    echo "[X] Error: BIND9 no está corriendo" >&2
    systemctl status bind9 --no-pager
    return 1
  fi
  
  if ! rndc status > /dev/null; then
    echo "[X] Error: rndc no puede comunicarse con BIND" >&2
    return 1
  fi
  
  echo "[✓] BIND9 está funcionando correctamente"
  return 0
}