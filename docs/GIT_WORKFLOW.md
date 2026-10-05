# Estrategia de ramas y convenciones

**Estrategia:** trunk-based development con ramas cortas.
- `main`: siempre desplegable. Protegida (ver `scripts/protect_main.sh`): solo se modifica con Pull Request,
  1 aprobación de otro integrante, CI en verde, sin force-push.
- Ramas de trabajo: `feat/...`, `fix/...`, `ci/...`, `infra/...`, `docs/...`.
- Versionado: etiquetas SemVer (`v1.0.0`, `v1.1.0`). Cada etiqueta dispara el CD.

**Commits:** Conventional Commits 1.0.0, por ejemplo
`feat(api): agrega endpoint de eventos`, `ci: agrega job de terraform validate`, `infra: define security group`,
`docs: documenta el despliegue`, `test: cubre estados inválidos`.

**Revisión:** el autor de un PR no puede aprobarlo; `CODEOWNERS` asigna revisor por área.
