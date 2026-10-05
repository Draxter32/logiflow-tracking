# Provisionar, desplegar y eliminar

## 1. Requisitos locales
Cuenta AWS (capa gratuita), AWS CLI configurado (`aws configure`), Terraform >= 1.6, par de claves SSH:
`ssh-keygen -t ed25519 -f ~/.ssh/logiflow_deploy -C logiflow`

## 2. Aprovisionar el ambiente (IaC)
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars      # pegue su clave pública
terraform fmt -recursive
terraform init
terraform plan -out tfplan
terraform apply tfplan | tee ../../docs/evidencia/terraform-apply.log
terraform output public_ip
```
Versione `.terraform.lock.hcl` (no versione `terraform.tfvars` ni `*.tfstate`).

## 3. Secretos en GitHub (Settings > Secrets and variables > Actions)
| Secreto | Valor |
|---|---|
| `EC2_HOST` | IP de `terraform output public_ip` |
| `EC2_SSH_KEY` | Contenido de la clave **privada** `~/.ssh/logiflow_deploy` |
| `POSTGRES_PASSWORD` | Clave larga y aleatoria (`openssl rand -hex 24` (use solo hexadecimal: la clave va dentro de una URL de conexión)) |

Cree además dos *Environments* (Settings > Environments): `staging` (sin reglas) y `production` con un revisor requerido (aprobación manual de la promoción).

## 4. Desplegar versión 1.0.0 y 1.1.0
```bash
git switch main && git pull
git tag -a v1.0.0 -m "Primera versión" && git push origin v1.0.0     # dispara CD
# Luego, por Pull Request, aplique el cambio de la 1.1.0:
git switch -c feat/filtro-estado
git apply release/v1.1.0.patch
git add -A && git commit -m "feat(api): filtro por estado y endpoint /stats"
git push -u origin feat/filtro-estado                               # abrir PR, revisar, merge
git switch main && git pull
git tag -a v1.1.0 -m "Filtro por estado y estadísticas" && git push origin v1.1.0
./scripts/smoke_test.sh http://$(terraform -chdir=infra/terraform output -raw public_ip)
```
Cada etiqueta se despliega primero en **staging** (puerto 8081, cerrado al público) y, tras la aprobación, se **promueve a producción** (puerto 80).
`/version` debe devolver `1.0.0` y luego `1.1.0`.

## 5. Eliminar el ambiente
```bash
cd infra/terraform && terraform destroy
```
(Hágalo solo después de la fecha de retroalimentación del docente: el ambiente debe seguir accesible.)

## Compromiso conocido
El SSH está abierto a Internet (protegido solo con clave) porque los runners de GitHub usan IPs dinámicas.
Mejora futura: AWS Systems Manager Session Manager + OIDC, sin puerto 22.
