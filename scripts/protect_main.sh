#!/usr/bin/env bash
# Protege la rama main: exige PR con 1 aprobación, sin force-push. Requiere GitHub CLI (gh) autenticado
# como administrador del repositorio.
# Uso:  ./scripts/protect_main.sh OWNER/REPO                 (completa: exige también CI en verde)
#       ./scripts/protect_main.sh OWNER/REPO --sin-checks    (etapa 1: aún no existe el CI)
set -euo pipefail
REPO="${1:?Uso: $0 OWNER/REPO [--sin-checks]}"
if [ "${2:-}" = "--sin-checks" ]; then
  CHECKS='null'
else
  CHECKS='{"strict": true, "contexts": ["Validaciones estáticas", "Pruebas automáticas", "Validar infraestructura (Terraform)"]}'
fi

gh api -X PUT "repos/${REPO}/branches/main/protection" --input - <<JSON
{
  "required_status_checks": ${CHECKS},
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "Rama main protegida en ${REPO}"
