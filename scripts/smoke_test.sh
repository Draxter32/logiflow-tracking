#!/usr/bin/env bash
# Prueba rápida de la aplicación desplegada. Uso: ./scripts/smoke_test.sh http://IP
set -euo pipefail
URL="${1:?Uso: $0 URL_BASE}"
echo "Versión:"; curl -fsS "$URL/version"; echo
echo "Salud:";   curl -fsS "$URL/health";  echo
echo "Creando entrega de prueba..."
curl -fsS -X POST "$URL/deliveries" -H 'Content-Type: application/json' \
  -d "{\"tracking_code\":\"DEMO-$(date +%s)\",\"destination\":\"Av. Apoquindo 4500, Las Condes\"}"; echo
echo "Listado:"; curl -fsS "$URL/deliveries"; echo
