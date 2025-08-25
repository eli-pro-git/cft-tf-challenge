terraform {
  backend "s3" {
    bucket       = "cfc-tf-state"
    key          = "tf-infra/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
    encrypt      = true
  }
}