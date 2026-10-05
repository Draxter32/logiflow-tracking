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
