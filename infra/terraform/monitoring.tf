# ---------- Monitoreo y logging (CloudWatch) ----------

# --- Grupos de logs ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project_name}/app"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/${var.project_name}/system"
  retention_in_days = var.log_retention_days
}

# --- Configuración del agente de CloudWatch (se guarda en SSM Parameter Store) ---
resource "aws_ssm_parameter" "cwagent_config" {
  name        = "/${var.project_name}/cloudwatch-agent/config"
  description = "Configuracion del agente de CloudWatch: logs de contenedores y metricas de memoria y disco"
  type        = "String"

  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/lib/docker/containers/*/*-json.log"
              log_group_name  = aws_cloudwatch_log_group.app.name
              log_stream_name = "{instance_id}/docker"
            },
            {
              file_path       = "/var/log/auth.log"
              log_group_name  = aws_cloudwatch_log_group.system.name
              log_stream_name = "{instance_id}/auth"
            },
            {
              file_path       = "/var/log/syslog"
              log_group_name  = aws_cloudwatch_log_group.system.name
              log_stream_name = "{instance_id}/syslog"
            },
          ]
        }
      }
    }
    metrics = {
      namespace = "CWAgent"
      append_dimensions = {
        InstanceId = "$${aws:InstanceId}"
      }
      aggregation_dimensions = [["InstanceId"]]
      metrics_collected = {
        mem  = { measurement = ["mem_used_percent"] }
        disk = { measurement = ["used_percent"], resources = ["/"] }
      }
    }
  })
}

# --- Instalación y configuración del agente mediante SSM (sin reemplazar la instancia) ---
resource "aws_ssm_association" "cwagent_install" {
  name             = "AWS-ConfigureAWSPackage"
  association_name = "${var.project_name}-instalar-cloudwatch-agent"

  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }

  targets {
    key    = "InstanceIds"
    values = [aws_instance.app.id]
  }

  depends_on = [aws_iam_role_policy_attachment.ssm_core]
}

resource "aws_ssm_association" "cwagent_configure" {
  name             = "AmazonCloudWatch-ManageAgent"
  association_name = "${var.project_name}-configurar-cloudwatch-agent"

  parameters = {
    action                        = "configure"
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = aws_ssm_parameter.cwagent_config.name
    optionalRestart               = "yes"
  }

  targets {
    key    = "InstanceIds"
    values = [aws_instance.app.id]
  }

  depends_on = [aws_ssm_association.cwagent_install]
}

# --- Métrica a partir de logs: errores de la aplicación ---
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.project_name}-errores-app"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "?\"500 Internal Server Error\" ?\"ERROR\" ?\"Traceback\""

  metric_transformation {
    name          = "AppErrores"
    namespace     = "LogiFlow"
    value         = "1"
    default_value = "0"
  }
}

# --- Notificaciones ---
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alertas"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- Alarmas ---
resource "aws_cloudwatch_metric_alarm" "cpu_alta" {
  alarm_name          = "${var.project_name}-cpu-alta"
  alarm_description   = "CPU de la instancia sobre 80% durante 10 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.app.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "estado_instancia" {
  alarm_name          = "${var.project_name}-fallo-estado-instancia"
  alarm_description   = "La instancia no pasa las comprobaciones de estado de EC2"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = aws_instance.app.id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "memoria_alta" {
  alarm_name          = "${var.project_name}-memoria-alta"
  alarm_description   = "Memoria usada sobre 85% (metrica del agente de CloudWatch)"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  dimensions          = { InstanceId = aws_instance.app.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "disco_lleno" {
  alarm_name          = "${var.project_name}-disco-lleno"
  alarm_description   = "Disco raiz usado sobre 80% (metrica del agente de CloudWatch)"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  dimensions          = { InstanceId = aws_instance.app.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "errores_app" {
  alarm_name          = "${var.project_name}-errores-aplicacion"
  alarm_description   = "Cinco o mas errores de la aplicacion en 5 minutos (detectados en los logs)"
  namespace           = "LogiFlow"
  metric_name         = "AppErrores"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.app_errors]
}

# --- Dashboard ---
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-operacion"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "CPU de la instancia (%)"
          region  = var.aws_region
          stat    = "Average"
          period  = 300
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Memoria y disco usados (%)"
          region = var.aws_region
          stat   = "Average"
          period = 300
          metrics = [
            ["CWAgent", "mem_used_percent", "InstanceId", aws_instance.app.id],
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.app.id],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Errores de la aplicacion (desde logs)"
          region  = var.aws_region
          stat    = "Sum"
          period  = 300
          metrics = [["LogiFlow", "AppErrores"]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "Comprobaciones de estado fallidas"
          region  = var.aws_region
          stat    = "Maximum"
          period  = 60
          metrics = [["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.app.id]]
        }
      },
      {
        type = "log", x = 0, y = 12, width = 24, height = 6
        properties = {
          title  = "Ultimos logs de la aplicacion"
          region = var.aws_region
          query  = "SOURCE '${aws_cloudwatch_log_group.app.name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          view   = "table"
        }
      },
    ]
  })
}
