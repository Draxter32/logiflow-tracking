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

## Monitoreo, logging y seguridad (Evaluación 3)
```mermaid
flowchart LR
  subgraph AWS[AWS - creado con Terraform]
    EC2[EC2 + Docker Compose] -->|agente CloudWatch: logs y metricas| CW[CloudWatch Logs y Metricas]
    CW --> AL[Alarmas] --> SNS[SNS: correo]
    CW --> DB[Dashboard logiflow-operacion]
    ROL[Rol IAM minimo privilegio] -.-> EC2
    SSM[Systems Manager] -->|instala y configura agente, Session Manager| EC2
    API[API de AWS: acciones de la cuenta] --> CT[CloudTrail]
    CT --> S3[(S3 privado y cifrado)]
    CT --> CWT[CloudWatch Logs: cloudtrail] --> AL
  end
```

Recursos de AWS declarados en `infra/terraform`: VPC, subred pública, Internet Gateway, tabla de rutas,
Security Group (80 abierto; 22 solo con clave; 5432 cerrado), Key Pair, instancia EC2 (disco cifrado, IMDSv2),
Elastic IP; rol e instance profile IAM (`iam.tf`); grupos de logs, parámetro SSM con la configuración del agente,
asociaciones SSM, filtros de métricas, tema SNS, 6 alarmas y dashboard (`monitoring.tf`); trail de CloudTrail,
bucket S3 y alarma de llamadas no autorizadas (`cloudtrail.tf`).
