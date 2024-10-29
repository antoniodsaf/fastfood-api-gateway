terraform {
  backend "s3" {
    bucket = "fastfood-tf"
    key = "api-gateway/terraform.tfstate"
    region = "us-east-1"
  }
}