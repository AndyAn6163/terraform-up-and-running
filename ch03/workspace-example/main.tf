resource "aws_instance" "example" {
  ami           = "ami-0ea3c35c5c3284d82"
  instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}

# S3 and DynamoDB has deployed, so no need to create the resource of aws_s3_bucket and aws_dynamodb_table
# just add the remote backend

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-andyan"
    key    = "workspace-example/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

