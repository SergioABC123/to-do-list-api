data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_db_subnet_group" "tasks" {
  name       = "todo-list-db"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "database" {
  name        = "todo-list-db"
  description = "Controla el acceso a PostgreSQL"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_api" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.api.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_db_instance" "tasks" {
  identifier        = "todo-list-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "tasks"
  username                    = "todo_admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.tasks.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  # La base del lab es desechable.
  skip_final_snapshot = true
}