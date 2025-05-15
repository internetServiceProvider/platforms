#!/bin/bash

# dns_full_test.sh - Validación completa de servidores DNS primario, secundario y local

set -euo pipefail

PRIMARY_IP="192.168.20.2"
SECONDARY_IP="192.168.20.3"
LOCAL_IP="127.0.0.1"
DOMAIN="akranes.xyz"
RECORD="www"
PTR_IP="192.168.20.100"
NON_EXISTENT="noexiste"
EXPECTED_WWW="192.168.20.100"
EXPECTED_MAIL="192.168.20.20"

echo "=== TEST DNS COMPLETO: $(date) ==="
echo "Dominio bajo prueba: $DOMAIN"
echo ""

# Función auxiliar
test_record() {
  local type=$1
  local server=$2
  local name=$3
  local expect=${4:-}

  echo -n "[$server] $name ($type): "
  result=$(dig +short @"$server" "$name" "$type" 2>/dev/null)

  if [[ -z "$result" ]]; then
    echo "✘ Sin respuesta"
    return 1
  elif [[ -n "$expect" && "$result" != "$expect" ]]; then
    echo "✘ Inesperado → $result (esperado: $expect)"
    return 1
  else
    echo "✔ $result"
    return 0
  fi
}

test_dnssec() {
  local server=$1
  echo -n "[$server] DNSSEC ($DOMAIN): "
  if dig +dnssec @"$server" "$DOMAIN" | grep -q "RRSIG"; then
    echo "✔ Firma RRSIG encontrada"
  else
    echo "✘ No hay RRSIG"
  fi
}

test_dnskey() {
  echo -n "[DNSKEY] $DOMAIN: "
  if dig DNSKEY "$DOMAIN" +dnssec @127.0.0.1 | grep -q "DNSKEY"; then
    echo "✔ Claves DNSKEY presentes"
  else
    echo "✘ No se encontraron DNSKEY"
  fi
}

test_axfr() {
  local server=$1
  echo -n "[$server] AXFR $DOMAIN: "
  if dig @"$server" "$DOMAIN" AXFR +time=3 +tries=1 2>/dev/null | grep -v '^;' | grep -q '\.'; then
    echo "✘ Transferencia permitida (inseguro)"
  else
    echo "✔ Transferencia bloqueada"
  fi
}

test_aa_flag() {
  local server=$1
  echo -n "[$server] Autoritatividad (aa): "
  if dig @"$server" "$RECORD.$DOMAIN" +noall +cmd | grep -q "flags:.* aa"; then
    echo "✔ Servidor autoritativo"
  else
    echo "✘ No es autoritativo"
  fi
}

test_nxdomain() {
  local server=$1
  echo -n "[$server] NXDOMAIN: "
  if dig @"$server" "$NON_EXISTENT.$DOMAIN" | grep -q "status: NXDOMAIN"; then
    echo "✔ NXDOMAIN correcto"
  else
    echo "✘ No respondió NXDOMAIN"
  fi
}

echo "== Test A Records =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP" "$LOCAL_IP"; do
  test_record A "$srv" "$RECORD.$DOMAIN" "$EXPECTED_WWW"
done
echo ""

echo "== Test PTR (reversa) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP" "$LOCAL_IP"; do
  echo -n "[$srv] PTR $PTR_IP: "
dig +short -x "$PTR_IP" @"$srv"

done
echo ""

echo "== Test DNSSEC (RRSIG) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP" "$LOCAL_IP"; do
  test_dnssec "$srv"
done
echo ""

echo "== Test DNSKEY =="
test_dnskey
echo ""

echo "== Test AXFR (seguridad) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP"; do
  test_axfr "$srv"
done
echo ""

echo "== Test Autoritatividad (aa flag) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP"; do
  test_aa_flag "$srv"
done
echo ""

echo "== Test de consistencia =="
echo -n "[mail] Primario:   "; dig +short @"$PRIMARY_IP" "mail.$DOMAIN"
echo -n "[mail] Secundario: "; dig +short @"$SECONDARY_IP" "mail.$DOMAIN"
echo ""

echo "== Test NXDOMAIN (registro inexistente) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP" "$LOCAL_IP"; do
  test_nxdomain "$srv"
done
echo ""

echo "=== TEST COMPLETADO ==="
