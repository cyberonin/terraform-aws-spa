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
  type        = list(any)
  description = "List of domains which will serve the application. If empty, will use the default cloudfront domain"
  default     = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN to use instead of the default cloudfront certificate"
  default     = ""
}

variable "distribution_price_class" {
  type        = string
  description = "CloudFront price class, which specifies where the distribution should be replicated, one of: PriceClass_100, PriceClass_200, PriceClass_All"
  default     = "PriceClass_100"
}

variable "distribution_viewer_protocal_policy" {
  type        = string
  description = "allow-all, https-only, or redirect-to-https"
  default     = "redirect-to-https"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to each resource that supports them"
  default     = {}
}
