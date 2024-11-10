provider "aws" {
  region = "us-east-2"
}

module "web-server-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name          = "webservers-prod"
  db_remote_stae_bucket = "terraform-up-and-running-state-andyan"
  db_remote_state_key   = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
