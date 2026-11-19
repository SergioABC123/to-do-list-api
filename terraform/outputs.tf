output "api_public_ip" {
  description = "IP pública de la instancia donde se ejecutará la API."
  value       = aws_instance.api.public_ip
}

output "database_host" {
  description = "Nombre DNS de la base de datos PostgreSQL."
  value       = aws_db_instance.tasks.address
}

output "database_secret_arn" {
  description = "ARN del secreto de credenciales administrado por RDS."
  value       = aws_db_instance.tasks.master_user_secret[0].secret_arn
}