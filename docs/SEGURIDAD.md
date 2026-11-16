# Seguridad en DevOps (criterio 3.3)

Responde a RS-1 a RS-6 y RT-1 a RT-3 de `docs/REQUISITOS.md`.

| Práctica | Implementación | Archivo |
|---|---|---|
| Mínimo privilegio | Rol de la instancia con una política propia: solo escribe en sus dos grupos de logs, publica métricas en el espacio `CWAgent` y lee su parámetro de configuración | `iam.tf` |
| Sin claves de larga duración | La instancia usa rol e instance profile; no se crea ningún `aws_iam_access_key` | `iam.tf` |
| Administración sin puertos | Session Manager (`AmazonSSMManagedInstanceCore`) permite entrar sin abrir el 22 | `iam.tf`, `outputs.tf` |
| Protección de credenciales | `POSTGRES_PASSWORD`, `EC2_HOST` y `EC2_SSH_KEY` en GitHub Secrets; `.env`, `*.tfvars` y `*.tfstate` fuera de Git | `.gitignore`, workflows |
| Red restringida | 80 público; 22 solo con llave; 5432 cerrado | `main.tf` |
| Protección del servidor | Disco cifrado, IMDSv2 obligatorio, contenedor sin root | `main.tf`, `Dockerfile` |
| Trazabilidad | CloudTrail multirregión con validación de integridad, S3 privado, cifrado, solo TLS y expiración a 90 días | `cloudtrail.tf` |
| Detección | Alarma ante llamadas denegadas a la API | `cloudtrail.tf` |
| Seguridad automática en CI | bandit, pip-audit y pruebas de seguridad de la IaC | `ci.yml`, `tests/infra` |
| Permisos mínimos en workflows | `permissions: contents: read` por defecto; ambiente `production` con aprobación | `ci.yml`, `cd.yml` |
| Rama principal protegida | PR obligatorio, CI en verde y sin forzar el historial | `scripts/protect_main.sh` |

## Riesgo residual
El puerto 22 sigue abierto porque el despliegue (CD) entra por SSH desde direcciones de GitHub que cambian; está
protegido solo con llave. La administración manual ya puede hacerse por Session Manager. Mejora propuesta: migrar
el despliegue a SSM con OIDC de GitHub y cerrar el 22 (`ssh_allowed_cidrs = []`).
