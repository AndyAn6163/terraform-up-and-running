provider "aws" {
  region = "us-east-2"
}

# 執行前先使用環境變數的方式塞入帳號密碼
# 注意 set 指令不要加上 double quote，他會把 double quote 也視為值的一部分，而 username 不接受 double quote 作為值
# 注意 password 不能小於 8 char
# set TF_VAR_db_username=xxx
# set TF_VAR_db_password=xxxxx
resource "aws_db_instance" "example" {
  allocated_storage = 10
  db_name           = "example_database"
  engine            = "mysql"
  # Starting on this date, Amazon RDS began automatically upgrading instances using db.t2 to the newer generation db.t3 instance class. 
  # Creating DB instances using the db.t2 instance class is no longer supported.
  instance_class = "db.t3.micro"
  # identifier - (Optional) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier.
  # identifier_prefix - (Optional) Creates a unique identifier beginning with the specified prefix. Conflicts with identifier.
  identifier_prefix = "terraform-up-and-running"
  # Determines whether a final DB snapshot is created before the DB instance is deleted. 
  # If true is specified, no DBSnapshot is created
  skip_final_snapshot = true

  # 永遠不要把密語儲存在程式碼裡面  
  # username = XXX
  # password = XXXXX
  username = var.db_username
  password = var.db_password
}

# Setting backend to remote backend s3
# 使用新的 key，因此狀態檔案與 s3、web-server-cluster 分開
# terraform init -backend-config ./backend.hcl
terraform {
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

# set command only use in CMD not powershell
# using terraform apply in powershell, terraform will ask you the username and poassword, not derived from env variable
# 注意 set 指令不要加上 double quote，他會把 double quote 也視為值的一部分，而 username 不接受 double quote 作為值
# 注意 password 不能小於 8 char
# set TF_VAR_db_username=xxx
# set TF_VAR_db_password=xxxxx
# echo %TF_VAR_db_username%
# echo %TF_VAR_db_password%
# terraform init -backend-config ./backend.hcl
# terraform apply
