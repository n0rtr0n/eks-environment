output "prime_generator_python_ecr_url" {
  description = "URL for the ECR Repository for Prime Generator Python"
  value       = aws_ecr_repository.prime_generator_python.repository_url
}
