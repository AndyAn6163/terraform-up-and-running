# backend.hcl

# s3 bucket name and region
bucket = "terraform-up-and-running-state-andyan"
region = "us-east-2"

# dynamodb_table name
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true