# Arquitectura propuesta

```mermaid
flowchart LR
  Dev[Desarrollador] -->|PR + revisión| GH[(GitHub repo)]
  GH -->|push / PR| CI[CI: lint, tests, terraform validate, build]
  GH -->|tag vX.Y.Z| CD[CD: release + deploy]
  CD -->|push imagen| GHCR[(GHCR)]
  CD -->|SSH + compose| EC2
  subgraph AWS[AWS - creado con Terraform]
    EIP[Elastic IP] --> EC2[EC2 Ubuntu 24.04]
    subgraph EC2[Docker Compose]
      APP[app FastAPI :8000] --> DB[(PostgreSQL + volumen)]
    end
  end
  GHCR -->|docker pull| EC2
  Usuario -->|HTTP :80| EIP
```

Recursos de AWS declarados en `infra/terraform`: VPC, subred pública, Internet Gateway, tabla de rutas,
Security Group (80 abierto; 22 solo con clave; 5432 cerrado), Key Pair, instancia EC2 (disco cifrado, IMDSv2),
Elastic IP.
