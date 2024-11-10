provider "aws" {
  region = "us-east-2"
}

module "web-server-cluster" {
  source = "../../../modules/services/webserver-cluster"
}
