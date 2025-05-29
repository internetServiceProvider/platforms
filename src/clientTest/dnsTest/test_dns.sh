#!/bin/bash
# test_dns.sh - Script de pruebas DNS mejorado

set -euo pipefail

# --- Configuración ---
# Cambiar la ip por la ip de cada servidor (ip de documentacion)
# 
PRIMARY_IP="192.0.2.1"
SECONDARY_IP="192.0.2.2"
FORWARD_JSON="/vagrant/config/zone_forward.json"
REVERSE_JSON="/vagrant/config/zone_reverse.json"
IP_TO_REVERSE="192.168.20.100"
TEST_RECORDS=("ns1" "ns2" "www" "mail") # si existen mas registro agregar aqui
TIMEOUT=3  # Segundos para timeout de consultas

# --- Validaciones iniciales ---
for cmd in jq dig; do
  command -v "$cmd" >/dev/null 2>&1 || { 
    echo "[X] Error: '$cmd' no está instalado." >&2
    exit 1
  }
done

for f in "$FORWARD_JSON" "$REVERSE_JSON"; do
  [[ -f "$f" ]] || { echo "[X] Error: Falta archivo $f" >&2; exit 1; }
done

DOMAIN=$(jq -r '.origin' "$FORWARD_JSON" | sed 's/\.$//')
[[ "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] || { 
  echo "[X] Error: Dominio '$DOMAIN' inválido" >&2
  exit 1
}

# --- Funciones de prueba ---
test_dns_query() {
  local server=$1 record=$2 query_type=${3:-A}
  echo -n "[$server] $record ($query_type): "
  local result
  if result=$(dig +short +time=$TIMEOUT +tries=1 @"$server" "$record" "$query_type" 2>/dev/null); then
    [[ -n "$result" ]] && echo "✔ $result" || echo "✘ Sin respuesta"
  else
    echo "✘ Error de consulta"
  fi
}

test_ptr_query() {
  local server=$1 ip=$2
  echo -n "[$server] PTR $ip: "
  if result=$(dig +short +time=$TIMEOUT +tries=1 @"$server" -x "$ip" 2>/dev/null); then
    [[ -n "$result" ]] && echo "✔ $result" || echo "✘ Sin respuesta"
  else
    echo "✘ Error de consulta"
  fi
}

test_axfr() {
  local server=$1 zone=$2
  echo "[AXFR] Probando $zone en $server..."
  if dig @"$server" "$zone" AXFR +time=$TIMEOUT +tries=1 2>&1 | grep -v '^;' | grep -q '\.'; then
    echo "[!] ADVERTENCIA: Transferencia de zona permitida (inseguro)"
    return 1
  else
    echo "[✓] Transferencia bloqueada correctamente"
    return 0
  fi
}

test_dnssec() {
  local server=$1 record=$2
  echo -n "[$server] DNSSEC $record: "
  if dig +dnssec @"$server" "$record" +time=$TIMEOUT +tries=1 2>/dev/null | grep -q "RRSIG"; then
    echo "✔ RRSIG encontrado"
    return 0
  else
    echo "✘ No hay firma RRSIG"
    return 1
  fi
}

check_connectivity() {
  local server=$1
  if ! ping -c 1 -W 1 "$server" &>/dev/null; then
    echo "[X] Error: No hay conectividad con $server" >&2
    return 1
  fi
  return 0
}

# --- Ejecución de pruebas ---
run_tests_for_server() {
  local SERVER_IP=$1 LABEL=$2

  echo && echo "== Pruebas en $LABEL ($SERVER_IP) =="

  check_connectivity "$SERVER_IP" || return 1

  for record in "${TEST_RECORDS[@]}"; do
    test_dns_query "$SERVER_IP" "$record.$DOMAIN"
    sleep 0.5
  done

  test_dns_query "$SERVER_IP" "$DOMAIN"
  test_ptr_query "$SERVER_IP" "$IP_TO_REVERSE"
  test_dnssec "$SERVER_IP" "$DOMAIN"
  test_axfr "$SERVER_IP" "$DOMAIN"
}

# --- Main ---
echo "=== INICIO DE PRUEBAS DNS - $(date) ==="
echo "Dominio bajo prueba: $DOMAIN"

failures=0
run_tests_for_server "$PRIMARY_IP" "PRIMARIO" || ((failures++))
run_tests_for_server "$SECONDARY_IP" "SECUNDARIO" || ((failures++))
run_tests_for_server "127.0.0.1" "LOCAL" || ((failures++))

echo && echo "=== RESUMEN FINAL ==="
if [[ "$failures" -eq 0 ]]; then
  echo "✔ Todas las pruebas completadas correctamente para el dominio: $DOMAIN"
  exit 0
else
  echo "✘ Se detectaron fallos en $failures servidor(es) DNS"
  exit 1
fi
