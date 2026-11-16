# Pruebas automatizadas (criterio 3.2)

| Tipo | Qué valida | Dónde |
|---|---|---|
| Unitarias y de API | Endpoints, reglas de negocio, filtros y estadísticas (SQLite en memoria) | `tests/test_api.py`, `tests/test_v1_1.py` |
| Configuración de la infraestructura | Que `infra/terraform` cumpla RS, RT y RM sin credenciales de AWS: base de datos no expuesta, IMDSv2, disco cifrado, rol IAM, sin comodines ni credenciales, CloudTrail con validación, bucket privado, alarmas con notificación, logs con retención, agente con logs y métricas | `tests/infra/test_terraform_config.py` |
| Calidad y seguridad del código | ruff, bandit, pip-audit | job `lint` de `ci.yml` |
| Validez de Terraform | `fmt`, `init`, `validate` | job `iac` de `ci.yml` |
| Despliegue | Construcción de la imagen y despliegue primero en staging y luego en producción con verificación de salud | `cd.yml`, `scripts/deploy.sh` |
| Funcionamiento en operación | `/health` y `/version` de la URL pública tras desplegar; flujo completo con `scripts/smoke_test.sh` | `cd.yml`, `scripts/smoke_test.sh` |

Todo corre en GitHub Actions en cada pull request y en cada etiqueta de versión; si algo falla, el cambio no se une
ni se despliega. GitHub Actions cumple aquí el rol que la actividad sugiere para AWS CodeBuild: ejecutar compilación,
pruebas y validaciones dentro del pipeline.

```bash
pip install -r requirements-dev.txt
pytest                      # unitarias, API e infraestructura
pytest tests/infra -v       # solo las pruebas de la IaC
```
