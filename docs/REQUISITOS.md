# Caso y requerimientos (Paso 1)

## Caso seleccionado
**LogiFlow Tracking**: microservicio de seguimiento de entregas en tiempo real para LogiFlow SpA, una empresa
ficticia de entregas de última milla. Permite registrar entregas y consultar su estado.

## Alcance y usuarios
- Operadores de LogiFlow: registran entregas y eventos de seguimiento (estado + coordenadas).
- Clientes retail (integración B2B): consultan el estado de una entrega por su código.
- Fuera de alcance: autenticación de usuarios, interfaz web, integración real con el sistema de flota.

## Requerimientos técnicos
| Ítem | Definición |
|---|---|
| Lenguaje / framework | Python 3.12, FastAPI, SQLAlchemy 2 |
| Servicios | `app` (API REST) y `db` (PostgreSQL 16) |
| Base de datos | PostgreSQL en producción; SQLite en memoria para pruebas |
| Dependencias | `requirements.txt` con versiones fijas |
| Puertos | App escucha en 8000 (contenedor) y se publica en 80 (host). PostgreSQL 5432 solo en red interna Docker |
| Persistencia | Volumen Docker `pgdata` |
| Variables de entorno | `DATABASE_URL`, `APP_VERSION`, `POSTGRES_*`, `APP_PORT`, `APP_TAG` |
| Secretos | `POSTGRES_PASSWORD`, `EC2_SSH_KEY`, `EC2_HOST` en GitHub Secrets; nunca en el código |

## Proveedor Cloud e IaC (justificación)
- **AWS (EC2 t3.micro, capa gratuita)**: proveedor líder y con documentación extensa. El plan gratuito para cuentas nuevas entrega créditos por 6 meses, que cubren el costo de este proyecto (aprox. US$12-13 al mes; verificar en la calculadora de AWS).
- **Terraform**: declarativo, agnóstico del proveedor, con `plan` previo a cada cambio y `destroy` para eliminar
  el ambiente completo, lo que da reproducibilidad y trazabilidad (todo versionado en Git).
- **Docker Compose sobre una sola instancia**: suficiente para el piloto; evita la complejidad de Kubernetes.
- **GitHub + GitHub Actions + GHCR**: repositorio, CI/CD y registro de imágenes en una sola plataforma, con
  secretos y entornos con aprobación integrados.

## Requerimientos de la gestión de la configuración en Cloud (Evaluación 3)
El sistema de gestión de la configuración es el conjunto de archivos de `infra/terraform/`, versionados en Git y
ejecutables con Terraform, más los workflows de `.github/workflows/`. Estos requerimientos son la referencia contra
la que se evalúan el monitoreo, las pruebas y la seguridad.

### Funcionales y técnicos
| Id | Requerimiento | Cómo se cumple |
|---|---|---|
| RF-1 | Todo recurso de AWS se crea y modifica solo con código (nada por consola) | `infra/terraform/*.tf` |
| RF-2 | El ambiente se puede crear y eliminar con un comando y es reproducible | `terraform apply` / `destroy` |
| RF-3 | La API responde `/health` y `/version` tras cada despliegue | Prueba de humo en `cd.yml` y `scripts/smoke_test.sh` |
| RF-4 | Los cambios de infraestructura se validan antes de unirse a `main` | Job `iac` y pruebas `tests/infra` en CI |

### Monitoreo y logging (RM)
| Id | Requerimiento | Implementación |
|---|---|---|
| RM-1 | Recolectar los logs de la aplicación y del sistema de forma centralizada | Agente de CloudWatch → `/logiflow/app` y `/logiflow/system` |
| RM-2 | Medir CPU, memoria, disco y estado de la instancia | Métricas `AWS/EC2` y `CWAgent`; dashboard `logiflow-operacion` |
| RM-3 | Detectar errores de la aplicación a partir de los logs | Filtro de métrica `AppErrores` y alarma (≥ 5 en 5 min) |
| RM-4 | Avisar por correo ante un incidente | 6 alarmas → tema SNS `logiflow-alertas` |
| RM-5 | Conservar los logs un tiempo acotado | Retención de 30 días |

### Seguridad DevOps (RS) y trazabilidad (RT)
| Id | Requerimiento | Implementación |
|---|---|---|
| RS-1 | Mínimo privilegio: la instancia usa un rol IAM acotado, sin claves de acceso | `iam.tf` |
| RS-2 | Ninguna credencial en el código ni en el informe | GitHub Secrets, `.gitignore`, prueba automática |
| RS-3 | Puertos mínimos: 80 público, 22 solo con llave, 5432 cerrado | Security Group |
| RS-4 | Disco cifrado y metadatos protegidos (IMDSv2) | `aws_instance.app` |
| RS-5 | Administración sin exponer puertos | AWS Systems Manager (Session Manager) |
| RS-6 | Revisión de seguridad automática en cada cambio | bandit, pip-audit y pruebas de seguridad de la IaC |
| RT-1 | Registrar todas las acciones de la cuenta AWS, con integridad verificable | CloudTrail con validación de archivos, multirregión |
| RT-2 | Registros de auditoría privados, cifrados y con expiración | Bucket S3 con bloqueo de acceso público, AES-256 y 90 días |
| RT-3 | Alertar ante llamadas denegadas a la API | Filtro y alarma `llamadas-api-no-autorizadas` |

### Estándares de seguridad adoptados
Principio de mínimo privilegio y buenas prácticas de IAM (Amazon Web Services, s. f.-a), controles de CloudTrail
recomendados por el CIS AWS Foundations Benchmark (Center for Internet Security, s. f.) y análisis estático en CI.
