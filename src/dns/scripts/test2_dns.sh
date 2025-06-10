#!/bin/bash

PRIMARY_IP="192.168.88.17"       # ns1
SECONDARY_IP="192.168.88.18"     # ns2
DOMAIN="akranes.xyz"
RECORDS=("ns1" "ns2" "www" "mail")
REVERSE_IPS=("192.168.88.17" "192.168.88.18" "192.168.88.19" "192.168.88.31")

echo "===== TEST DE DNS PRIMARIO ($PRIMARY_IP) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short @"$PRIMARY_IP" "$r.$DOMAIN"
done

echo ""
echo "===== TEST DE DNS SECUNDARIO ($SECONDARY_IP) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short @"$SECONDARY_IP" "$r.$DOMAIN"
done

echo ""
echo "===== TEST PTR REVERSE (en primario) ====="
for i in "${!REVERSE_IPS[@]}"; do
  ip="${REVERSE_IPS[$i]}"
  echo -n "[PTR] $ip -> "
  dig +short -x "$ip" @"$PRIMARY_IP"
done

echo ""
echo "===== TEST PTR REVERSE (en secundario) ====="
for i in "${!REVERSE_IPS[@]}"; do
  ip="${REVERSE_IPS[$i]}"
  echo -n "[PTR] $ip -> "
  dig +short -x "$ip" @"$SECONDARY_IP"
done

echo ""
echo "===== TRANSFERENCIA DE ZONA (AXFR desde secundario) ====="
dig @"$SECONDARY_IP" "$DOMAIN" AXFR | grep -v '^;'

echo ""
echo "===== TEST DE RESOLUCIÓN GLOBAL (localhost DNS) ====="
for r in "${RECORDS[@]}"; do
  echo -n "[$r] -> "
  dig +short "$r.$DOMAIN"
done

echo "=== TRACE desde raíz hasta $DOMAIN ==="
dig +trace +nodnssec "$DOMAIN"

echo
echo "=== PRUEBA DIRECTA EN AUTORITATIVO ==="
NS=$(dig +short NS "$DOMAIN" @8.8.8.8 | head -n1)
echo "Usando NS: $NS"
dig +short "www.$DOMAIN" A @"$NS"
