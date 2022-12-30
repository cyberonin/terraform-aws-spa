provider "aws" {
  region  = "us-east-1"
  profile = ""
}

provider "aws" {
  alias   = "spa"
  region  = "ap-southeast-1"
  profile = ""
}

module "tf-example" {
  # source = "github.com/cyberonin/terraform-aws-spa"
  source = "../"

  # providers = {
  #   aws = aws.spa
  # }

  label_namespace          = "example"
  label_env                = "dev"
  label_app                = "app"
  domain_names             = ["example.domain.net"]
  distribution_price_class = "PriceClass_All" # PriceClass_All, PriceClass_100, PriceClass_200, default PriceClass_100

  acm_certificate_arn = "required"
}

resource "aws_s3_object" "basic_index" {
  bucket        = module.tf-example.spa_bucket_name
  key           = "index.html"
  content       = "<h1>Hello World</h1>"
  content_type  = "text/html"
  cache_control = "no-cache no-store"
}
