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
  type = list(any)
}

variable "acm_certificate_arn" {
  type = string
}

variable "distribution_price_class" {
  type        = string
  description = "PriceClass_All, PriceClass_200, PriceClass_100"
  default     = "PriceClass_100"
}

variable "distribution_viewer_protocal_policy" {
  type        = string
  description = "allow-all, https-only, or redirect-to-https"
  default     = "redirect-to-https"
}

variable "basic_auth_enabled" {
  type    = bool
  default = false
}

variable "username" {
  type    = string
  default = ""
}

variable "password" {
  type    = string
  default = ""
}

