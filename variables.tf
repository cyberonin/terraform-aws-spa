variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "aws_shared_credentials_file" {
  type    = string
  default = "~/.aws/credentials"
}

variable "label_namespace" {
  type = string
}

variable "label_env" {
  type = string
}

variable "label_app" {
  type = string
}

variable "domain_names" {
  type = list
}

variable "acm_certificate_arn" {
  type = string
}

variable "distribution_price_class" {
  type        = string
  description = "PriceClass_All, PriceClass_200, PriceClass_100"
  default     = "PriceClass_100"
}

variable "tag_project" {}
variable "tag_environment" {}
