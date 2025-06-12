#!/bin/bash

# dns_full_test.sh - Validación completa de servidores DNS primario, secundario y local

set -euo pipefail

PRIMARY_IP="192.168.88.17"       # ns1
SECONDARY_IP="192.168.88.18"     # ns2
LOCAL_IP="127.0.0.1"
DOMAIN="akranes.xyz"
RECORDS=("www" "mail" "ns1" "ns2")
PTR_IPS=("192.168.88.17" "192.168.88.18" "192.168.88.31")
NON_EXISTENT="noexiste"

# Valores esperados para registros A (ajustados)
EXPECTED_WWW="192.168.50.20"
EXPECTED_MAIL="192.168.88.31"

echo "=== TEST DNS COMPLETO: $(date) ==="
echo "Dominio bajo prueba: $DOMAIN"
echo ""

# Función auxiliar para test de registros A
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
  fi

  # Si es CNAME, resolver el A del destino
 # Si es CNAME, resolver el A del destino
if [[ $result == *"." ]]; then
  # El resultado es el CNAME directamente
  cname_target=$result
  # Resolvemos la IP del CNAME
  result=$(dig +short @"$server" "$cname_target" A 2>/dev/null)
fi
}

# Función para test DNSSEC (RRSIG)
test_dnssec() {
  local server=$1
  echo -n "[$server] DNSSEC ($DOMAIN): "
  if dig +dnssec @"$server" "$DOMAIN" | grep -q "RRSIG"; then
    echo "✔ Firma RRSIG encontrada"
  else
    echo "✘ No hay RRSIG"
  fi
}

# Función para test DNSKEY
test_dnskey() {
  echo -n "[DNSKEY] $DOMAIN: "
  if dig DNSKEY "$DOMAIN" +dnssec @127.0.0.1 | grep -q "DNSKEY"; then
    echo "✔ Claves DNSKEY presentes"
  else
    echo "✘ No se encontraron DNSKEY"
  fi
}

# Test transferencia de zona (AXFR)
test_axfr() {
  local server=$1
  echo -n "[$server] AXFR $DOMAIN: "
  if dig @"$server" "$DOMAIN" AXFR +time=3 +tries=1 2>/dev/null | grep -v '^;' | grep -q '\.'; then
    echo "✘ Transferencia permitida (inseguro)"
  else
    echo "✔ Transferencia bloqueada"
  fi
}

# Test bandera autoritativa (aa)
test_aa_flag() {
  local server=$1
  echo -n "[$server] Autoritatividad (aa): "
  if dig @"$server" "${RECORDS[0]}.$DOMAIN" +noall +cmd | grep -q "flags:.* aa"; then
    echo "✔ Servidor autoritativo"
  else
    echo "✘ No es autoritativo"
  fi
}

# Test NXDOMAIN (registro inexistente)
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
  for rec in "${RECORDS[@]}"; do
    expected=""
    [[ $rec == "www" ]] && expected=$EXPECTED_WWW
    [[ $rec == "mail" ]] && expected=$EXPECTED_MAIL
    test_record A "$srv" "$rec.$DOMAIN" "$expected"
  done
done
echo ""

echo "== Test PTR (reversa) =="
for srv in "$PRIMARY_IP" "$SECONDARY_IP" "$LOCAL_IP"; do
  for ip in "${PTR_IPS[@]}"; do
    echo -n "[$srv] PTR $ip: "
    dig +short -x "$ip" @"$srv"
  done
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
