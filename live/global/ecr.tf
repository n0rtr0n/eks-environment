resource "aws_ecr_repository" "prime_generator_python" {
  name                 = "prime_generator_python"
  image_tag_mutability = "MUTABLE"
}

