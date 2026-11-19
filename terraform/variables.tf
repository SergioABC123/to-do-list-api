variable "aws_region" {
  description = "Región donde se ejecuta el AWS Learner Lab."
  type        = string
}

variable "api_ingress_cidr" {
  description = "Rango de IPs que puede acceder al puerto 8000 de la API."
  type        = string
}

variable "ec2_public_key" {
  description = "Contenido de la clave pública que se registrará en EC2."
  type        = string
}

variable "repository_url" {
  description = "URL HTTPS del repositorio de GitHub que contiene la API."
  type        = string
}