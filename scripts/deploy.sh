#!/usr/bin/env bash
# Despliega una versión en el servidor EC2 y verifica que quedó en línea.
# Lo ejecuta el workflow de CD (cd.yml). Uso: scripts/deploy.sh DIRECTORIO PUERTO
# Variables requeridas (vienen de los secretos de GitHub): EC2_HOST VERSION IMAGE DB_PASSWORD GHCR_TOKEN GH_ACTOR
set -euo pipefail
DIR="${1:?directorio remoto}"; PORT="${2:?puerto}"
KEY="$HOME/.ssh/deploy_key"
SSH=(ssh -i "$KEY" "ubuntu@${EC2_HOST}")
IMAGE_LC=$(echo "$IMAGE" | tr '[:upper:]' '[:lower:]')

"${SSH[@]}" "mkdir -p ${DIR}"
scp -i "$KEY" docker-compose.yml "ubuntu@${EC2_HOST}:${DIR}/docker-compose.yml"

# El .env se genera en el servidor desde los secretos; nunca vive en Git
printf 'POSTGRES_DB=logiflow\nPOSTGRES_USER=logiflow\nPOSTGRES_PASSWORD=%s\nAPP_IMAGE=%s\nAPP_TAG=%s\nAPP_PORT=%s\n' \
  "$DB_PASSWORD" "$IMAGE_LC" "$VERSION" "$PORT" | "${SSH[@]}" "umask 077; cat > ${DIR}/.env"

echo "$GHCR_TOKEN" | "${SSH[@]}" "docker login ghcr.io -u '${GH_ACTOR}' --password-stdin"
"${SSH[@]}" "cd ${DIR} && docker compose pull && docker compose up -d --remove-orphans && docker image prune -f"

# Prueba de humo: la versión desplegada debe coincidir con la etiqueta
for i in $(seq 1 20); do
  RESP=$("${SSH[@]}" "curl -fsS http://127.0.0.1:${PORT}/version" || true)
  echo "intento ${i}: ${RESP}"
  if echo "$RESP" | grep -q "\"${VERSION}\""; then echo "OK: ${VERSION} en ${DIR}"; exit 0; fi
  sleep 6
done
echo "La versión ${VERSION} no quedó en línea en ${DIR}" >&2
exit 1
