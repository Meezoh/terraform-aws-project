terraform {
  backend "s3" {
    bucket       = "s3-mizo-bucket-one"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

