output "public_ip" {
  description = "IP pública fija de la aplicación (usar como secreto EC2_HOST)"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "URL de la aplicación"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  description = "Comando para conectarse por SSH"
  value       = "ssh ubuntu@${aws_eip.app.public_ip}"
}

output "dashboard_name" {
  description = "Dashboard de CloudWatch con las metricas del servicio"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_topic_arn" {
  description = "Tema SNS que recibe las alarmas"
  value       = aws_sns_topic.alerts.arn
}

output "cloudtrail_bucket" {
  description = "Bucket S3 con los registros de CloudTrail"
  value       = aws_s3_bucket.trail.id
}

output "ssm_session_command" {
  description = "Acceso a la instancia por Session Manager (sin abrir puerto)"
  value       = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.aws_region}"
}
