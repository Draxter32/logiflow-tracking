# Roles y orden de Pull Requests (ejemplo para 3 integrantes)

Cada PR lo abre una persona y lo aprueba OTRA. Título del PR = mensaje de commit convencional (se usa "Squash and merge").

| Orden | Autor | Rama | Contenido | Revisa |
|---|---|---|---|---|
| 0 | A | (directo a main) | README.md y .gitignore iniciales; luego protección de main | - |
| 1 | B | docs/requisitos-y-flujo | docs/REQUISITOS.md, GIT_WORKFLOW.md, CONTRIBUTING.md, plantilla de PR, CODEOWNERS | A |
| 2 | A | feat/api-base | app/, tests/, requirements*, pyproject.toml | C |
| 3 | C | infra/terraform-aws | infra/terraform/ | B |
| 4 | B | build/contenedores | Dockerfile, .dockerignore, docker-compose.yml, .env.example | A |
| 5 | A | ci/pipeline-integracion | .github/workflows/ci.yml (después: proteger main CON checks) | C |
| 6 | C | ci/entrega-continua | cd.yml, scripts/, docs/ARQUITECTURA.md, DEPLOY.md | B |
| 7 | B | feat/filtro-estado | parche release/v1.1.0.patch (versión 1.1.0) | A |
| 8 | cualquiera | docs/evidencias | log de terraform apply y .terraform.lock.hcl | otro |

Con 2 integrantes se alternan; con 4 se reparten los PR 1 a 8. Todos deben quedar con al menos 1 PR y varios commits.
