provider "aws" {
  version                 = "~> 3.11"
  region                  = var.aws_region
  profile                 = var.aws_profile
  shared_credentials_file = var.aws_shared_credentials_file
}
