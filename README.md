# LogiFlow Tracking

Microservicio de seguimiento de entregas con CI/CD e infraestructura como código.
Evaluación sumativa — Fundamentos de DevOps (INACAP).

**Stack:** FastAPI · PostgreSQL · Docker Compose · GitHub Actions · GHCR · Terraform · AWS EC2

## Estructura
```
app/                 código de la API
tests/               pruebas automáticas (pytest)
Dockerfile           imagen de la aplicación
docker-compose.yml   servicios: app + PostgreSQL (volumen persistente)
.github/workflows/   ci.yml (integración continua) y cd.yml (entrega continua)
infra/terraform/     infraestructura como código del ambiente AWS
scripts/             despliegue, protección de rama y prueba de humo
docs/                requisitos, arquitectura, flujo Git, despliegue, plan de trabajo
```

## Ejecutar localmente
```bash
cp .env.example .env            # edite POSTGRES_PASSWORD
docker compose up --build       # API en http://localhost:8000 (docs en /docs)
pip install -r requirements-dev.txt && pytest
```

## Endpoints
`GET /health` · `GET /version` · `POST /deliveries` · `GET /deliveries` · `GET /deliveries/{codigo}` ·
`POST|GET /deliveries/{codigo}/events` · (v1.1.0) `GET /deliveries?status=` y `GET /stats`

## Flujo
PR → CI (lint, bandit, pip-audit, pytest, terraform validate, build) → merge a `main` → etiqueta `vX.Y.Z` →
CD (imagen en GHCR + despliegue SSH a EC2 + prueba de humo). Detalle en `docs/DEPLOY.md`.
