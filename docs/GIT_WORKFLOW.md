# Estrategia de ramas y convenciones

**Estrategia:** trunk-based development con ramas cortas.

- `main`: siempre desplegable. Está protegida (Settings > Branches):
  - todo cambio entra por Pull Request con 1 aprobación;
  - las aprobaciones se descartan si se suben cambios nuevos;
  - deben pasar las 3 verificaciones del CI (`Validaciones estáticas`, `Pruebas automáticas` y `Validar infraestructura (Terraform)`);
  - la rama debe estar actualizada antes de fusionar;
  - historial lineal (solo *squash merge*), sin force-push ni borrado y sin excepciones para administradores.
- Ramas de trabajo: `feat/...`, `fix/...`, `ci/...`, `infra/...`, `build/...`, `docs/...`.
- Versionado: etiquetas SemVer (`v1.0.0`, `v1.1.0`). Cada etiqueta dispara el CD (CI, publicación de la imagen, staging y, con aprobación manual, producción).

**Commits:** Conventional Commits 1.0.0, por ejemplo
`feat(api): agrega endpoint de eventos`, `ci: agrega job de terraform validate`, `infra: define security group`,
`docs: documenta el despliegue`, `test: cubre estados inválidos`, `fix(ci): ejecuta el script de despliegue con bash`.

**Revisión:** el autor de un PR no puede aprobarlo. El proyecto es individual (autorizado por el docente), por lo que las
aprobaciones las realiza una segunda cuenta del mismo autor (`crisncs231`), declarada en el informe.
