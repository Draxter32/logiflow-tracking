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
