
# resource "aws_db_subnet_group" "test" {
#   name       = "test"
#   subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

#   tags = {
#     Name = "My DB subnet group"
#   }
# }

# #DB for testing 
# resource "aws_db_instance" "test" {
#   allocated_storage        = 10
#   db_name                  = "mydb"
#   engine                   = "postgres"
#   instance_class           = "db.t3.micro"
#   username                 = "foo"
#   password                 = "foobarbaz" #
#   publicly_accessible      = false
#   skip_final_snapshot      = true
#   delete_automated_backups = true
#   db_subnet_group_name     = aws_db_subnet_group.test.name
#   vpc_security_group_ids = [
#     aws_security_group.postgres.id
#   ]
# }

# resource "aws_security_group" "postgres" {
#   name        = "postgres"
#   description = "Security group for PostgreSQL RDS instance"
#   vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

#   ingress {
#     from_port = 5432
#     to_port   = 5432
#     protocol  = "tcp"
#     security_groups = [
#       aws_security_group.tailscale_subnet_router.id
#     ]
#   }

#   # Allow all outbound traffic (default)
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Environment = local.env
#     Name        = "postgres"
#   }
# }
