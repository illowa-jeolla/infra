resource "aws_db_subnet_group" "this" {
  name        = var.subnet_group_name
  description = "Private data subnets for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.subnet_group_name
  })
}

resource "aws_db_parameter_group" "this" {
  name        = var.parameter_group_name
  description = "PostgreSQL 17 parameters for ${var.identifier}"
  family      = "postgres17"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = var.parameter_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  port     = 5432

  password_wo         = var.master_password
  password_wo_version = var.master_password_version

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  availability_zone      = var.availability_zone
  multi_az               = false
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  backup_retention_period  = var.backup_retention_days
  backup_window            = "20:00-21:00"
  maintenance_window       = "sun:21:00-sun:22:00"
  copy_tags_to_snapshot    = true
  delete_automated_backups = false

  auto_minor_version_upgrade          = true
  allow_major_version_upgrade         = false
  apply_immediately                   = false
  performance_insights_enabled        = false
  monitoring_interval                 = 0
  iam_database_authentication_enabled = false

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final"

  tags = merge(var.tags, {
    Name = var.identifier
  })

  lifecycle {
    prevent_destroy = true
  }
}
