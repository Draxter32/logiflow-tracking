# Roles y registro de pull requests

El proyecto se desarrolla de forma **individual**, con autorización del docente. El autor (`Draxter32`) asume todos los roles
y la revisión de los pull requests la realiza una segunda cuenta declarada (`crisncs231`).

| Rol | Responsable | Alcance |
|---|---|---|
| Desarrollo backend | Draxter32 | API FastAPI, modelos y pruebas |
| DevOps / IaC | Draxter32 | Terraform, pipeline de CI y entrega continua, secretos |
| Contenedores / QA | Draxter32 | Dockerfile, docker-compose, pruebas de humo y evidencias |
| Revisión de pull requests | crisncs231 | Aprobación de los PR antes de fusionar |

## Pull requests (todos con commit convencional, aprobados por la cuenta revisora y fusionados con squash)

| PR | Contenido |
|---|---|
| #1 | Infraestructura como código (Terraform) |
| #2 | API de seguimiento de entregas y pruebas |
| #3 | Dockerfile y docker-compose |
| #4 | Documentación del proyecto |
| #5 | Entrega continua (CD) con staging y producción |
| #6 | Pipeline de integración continua (CI) |
| #7 | Corrección: ejecutar el script de despliegue con bash |
| #8 | Versión 1.1.0: filtro por estado y endpoint de estadísticas |
