# Informe – Evidencia de implementación de infraestructura como código en ambientes Cloud

**Asignatura:** Fundamentos de DevOps · **Carrera:** Ingeniería en Informática · **Sección:** P TILE23
**Repositorio:** https://github.com/Draxter32/logiflow-tracking

## 1. Caso
LogiFlow SpA es una empresa de entregas de última milla que necesita saber el estado de cada entrega casi en tiempo
real. LogiFlow Tracking es la API que lo permite (FastAPI + PostgreSQL en contenedores, sobre una instancia EC2).
La necesidad de esta etapa es operar el servicio con visibilidad y control: saber cuándo falla, quién cambió qué en
la cuenta y que los accesos sean los mínimos, todo declarado como código y no configurado a mano.

## 2. Requerimientos
Están definidos en `docs/REQUISITOS.md` (RF, RM, RS y RT). Resumen: toda la infraestructura se crea con Terraform
(RF-1/2); los logs y las métricas se centralizan en CloudWatch y generan alarmas por correo (RM-1 a RM-5); la
instancia usa un rol de mínimo privilegio, sin claves, con puertos mínimos y disco cifrado (RS-1 a RS-6); y
CloudTrail registra las acciones de la cuenta de forma verificable (RT-1 a RT-3).

## 3. Diseño de la solución
Diagrama en `docs/ARQUITECTURA.md`. La instancia EC2 ejecuta la API y la base de datos con Docker Compose. Un agente
de CloudWatch, instalado y configurado por Systems Manager, envía logs y métricas a CloudWatch, donde las alarmas
publican en SNS. CloudTrail guarda los registros en un bucket S3 privado y los copia a CloudWatch Logs.

| Archivo | Contenido |
|---|---|
| `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` | Red, Security Group, EC2, IP elástica |
| `iam.tf` | Rol, política de mínimo privilegio e instance profile |
| `monitoring.tf` | Logs, agente, filtro de métricas, SNS, 6 alarmas y dashboard |
| `cloudtrail.tf` | Trail, bucket S3 seguro, envío a CloudWatch y alarma de llamadas denegadas |

## 4. Infraestructura como código
```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars     # clave pública SSH y alert_email
terraform init && terraform plan -out tfplan && terraform apply tfplan
```
Los recursos nuevos se agregan a la instancia existente sin reemplazarla (el perfil IAM se asocia en caliente y el
agente se instala por SSM, no por `user_data`). Pasos completos en `docs/DEPLOY.md`.

## 5. Monitoreo y logging
Detalle en `docs/MONITOREO.md`. Logs de los contenedores y del sistema, métricas de CPU, memoria, disco y estado,
una métrica derivada de los logs (`AppErrores`), dashboard `logiflow-operacion` y seis alarmas con aviso por correo.
Evidencias: `docs/evidencia/` (dashboard, logs, alarmas, correo, CloudTrail).

## 6. Pruebas automatizadas
Detalle en `docs/PRUEBAS.md`. Pruebas unitarias y de API, pruebas que verifican la configuración de la
infraestructura contra los requerimientos (`tests/infra`), análisis estático y de dependencias, validación de
Terraform y prueba de humo tras cada despliegue, todo ejecutado por GitHub Actions en cada cambio.

## 7. Seguridad DevOps
Detalle en `docs/SEGURIDAD.md`: rol IAM de mínimo privilegio sin claves de acceso, secretos en GitHub Secrets,
puertos mínimos, disco cifrado, IMDSv2, administración por Session Manager, CloudTrail con validación de integridad
y alerta ante llamadas denegadas. El puerto 22 sigue abierto con llave para el despliegue y se documenta como riesgo
residual con su mejora propuesta.

## 8. Reflexión final
Esta etapa me mostró que la infraestructura no termina cuando el servidor está funcionando: sin logs y alarmas no hay
forma de saber que algo falló, y sin trazabilidad no se puede explicar qué cambió. Definir primero los requerimientos
de monitoreo y seguridad hizo más fácil decidir qué alarmas crear y qué permisos dar, porque cada recurso responde a
un requerimiento concreto. Escribir pruebas que leen el código de Terraform me permitió comprobar esos requerimientos
en cada pull request, antes de gastar tiempo o dinero en AWS.

Las dificultades principales fueron ajustar el rol IAM para que fuera realmente acotado (PutMetricData no admite
limitar por recurso, por lo que se limitó por espacio de nombres), instalar el agente sin reemplazar la instancia
existente y conciliar el despliegue por SSH con el objetivo de cerrar el puerto 22.

La solución mejora la operación porque los incidentes se detectan por correo en vez de por reclamos; la seguridad,
porque los permisos son mínimos y las acciones quedan auditadas; y la automatización, porque el ambiente completo,
con su monitoreo, se crea y se elimina con código.

## Referencias
Amazon Web Services. (s. f.-a). *Security best practices in IAM*. AWS Identity and Access Management User Guide. https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

Amazon Web Services. (s. f.-b). *Amazon CloudWatch User Guide*. https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

Amazon Web Services. (s. f.-c). *AWS CloudTrail User Guide*. https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html

Amazon Web Services. (s. f.-d). *AWS Systems Manager User Guide*. https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html

Amazon Web Services. (s. f.-e). *AWS CodeBuild User Guide*. https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html

Center for Internet Security. (s. f.). *CIS Amazon Web Services Foundations Benchmark*. https://www.cisecurity.org/benchmark/amazon_web_services

HashiCorp. (s. f.). *Terraform documentation*. https://developer.hashicorp.com/terraform/docs
