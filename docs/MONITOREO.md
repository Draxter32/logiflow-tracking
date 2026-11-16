# Monitoreo y logging (criterio 3.1)

Definido en `infra/terraform/monitoring.tf` y `cloudtrail.tf`. Responde a los requerimientos RM-1 a RM-5 y RT-1 a RT-3
de `docs/REQUISITOS.md`.

## Qué se monitorea y por qué
| Componente | Señal | Para qué sirve |
|---|---|---|
| Logs de los contenedores (`/logiflow/app`) | Salida de la API y de PostgreSQL | Diagnosticar errores y seguir las peticiones |
| Logs del sistema (`/logiflow/system`) | `auth.log` y `syslog` | Detectar intentos de acceso por SSH y fallas del servidor |
| Instancia EC2 | CPU, comprobaciones de estado | Saber si el servidor está sobrecargado o caído |
| Agente de CloudWatch | Memoria y disco usados | Anticipar que el servidor se quede sin recursos |
| Logs de la API | Métrica `AppErrores` (filtro de métrica) | Detectar fallas de la aplicación sin instrumentar el código |
| CloudTrail | Acciones en la cuenta AWS | Auditoría y alerta de llamadas denegadas |

## Cómo funciona
1. Terraform crea el parámetro SSM `/logiflow/cloudwatch-agent/config` con la configuración del agente.
2. Dos asociaciones de Systems Manager instalan el agente en la instancia y lo configuran con ese parámetro; así la
   instancia no se reemplaza ni se instala nada a mano.
3. El agente envía logs y métricas (`CWAgent`) cada 60 segundos.
4. Las alarmas publican en el tema SNS `logiflow-alertas`, que envía un correo a `alert_email`.

## Alarmas
| Alarma | Condición | Respuesta esperada |
|---|---|---|
| `logiflow-cpu-alta` | CPU > 80 % por 10 min | Revisar procesos y evaluar un tipo de instancia mayor |
| `logiflow-fallo-estado-instancia` | `StatusCheckFailed` > 0 por 2 min | Reiniciar o reemplazar la instancia con Terraform |
| `logiflow-memoria-alta` | Memoria > 85 % por 10 min | Revisar contenedores |
| `logiflow-disco-lleno` | Disco > 80 % | Limpiar imágenes (`docker system prune`) o ampliar el volumen |
| `logiflow-errores-aplicacion` | ≥ 5 errores en 5 min | Revisar `/logiflow/app` |
| `logiflow-llamadas-api-no-autorizadas` | ≥ 1 llamada denegada en 5 min | Revisar CloudTrail y rotar credenciales si corresponde |

## Cómo verificarlo
```bash
./scripts/verify_monitoring.sh us-east-2          # alarmas, logs, CloudTrail y agente
aws cloudwatch set-alarm-state --alarm-name logiflow-cpu-alta --state-value ALARM --state-reason demo
```
La segunda orden fuerza la alarma para mostrar que llega el correo. Dashboard: CloudWatch > Dashboards >
`logiflow-operacion`.

## Evidencias a capturar
Dashboard con datos, grupo de logs `/logiflow/app` con líneas recientes, lista de alarmas en estado OK,
correo de una alarma, trail de CloudTrail "Registrando" y un evento en su historial.
