#!/bin/bash

# test_dns.sh - Pruebas para DNS primario, secundario y autoridad
# Requiere dig instalado (dnsutils)

PRIMARY_IP="192.168.20.2"
SECONDARY_IP="192.168.20.3"
DOMAIN="akranes.xyz"
RECORDS=("ns1" "ns2" "www")
REVERSE_ZONE=$(jq -r '.origin' /vagrant/config/zone_reverse.json)
IP_TO_REVERSE="192.168.20.100"  # ejemplo, ajusta según zona reverse

echo "===== TEST DE DNS PRIMARIO ($PRIMARY_IP) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short @$PRIMARY_IP $r.$DOMAIN
done

echo -n "[PTR] -> "
dig +short -x $IP_TO_REVERSE @$PRIMARY_IP

echo ""
echo "===== TEST DE DNS SECUNDARIO ($SECONDARY_IP) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short @$SECONDARY_IP $r.$DOMAIN
done

echo -n "[PTR] -> "
dig +short -x $IP_TO_REVERSE @$SECONDARY_IP

echo ""
echo "===== TRANSFERENCIA DE ZONA (AXFR desde secundario) ====="
dig @$SECONDARY_IP $DOMAIN AXFR | grep -v ';'

echo ""
echo "===== TEST DE RESOLUCIÓN GLOBAL (localhost DNS) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short $r.$DOMAIN
done
echo "=== TRACE desde raíz hasta $DOMAIN ==="
dig +trace +nodnssec $DOMAIN

echo
echo "=== PRUEBA DIRECTA EN AUTORITATIVO ==="
# Agarro el primer NS que devuelve +trace
NS=$(dig +short NS $DOMAIN @8.8.8.8 | head -n1)
echo "Usando NS: $NS"
dig +short $RECORD.$DOMAIN A @"$NS"
