variable "aws_region" {
  description = "Región de AWS donde se crea el ambiente"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (t3.micro es de bajo costo y se cubre con los créditos del plan gratuito)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "Clave pública SSH (contenido de id_ed25519.pub) para acceder a la instancia"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "Rangos CIDR con acceso SSH. El pipeline de CD corre en IPs dinámicas de GitHub, por eso el valor por defecto es abierto y el acceso se protege solo con clave."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "logiflow"
}
