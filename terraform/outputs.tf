output "api_public_ip" {
  description = "IP pública de la instancia donde se ejecutará la API."
  value       = aws_instance.api.public_ip
}