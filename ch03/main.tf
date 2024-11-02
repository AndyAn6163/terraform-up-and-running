provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-andyan"

  # Preven accidential deletion of this S3 bucket
  lifecycle {
    # in prod environment, you should set prevent_destroy = true
    # prevent_destroy = true
  }
  # if you want to use terraform destroy to delete bucket but bucket with version ebabled 
  # get Errot : The bucket you tried to delete is not empty. You must delete all versions in the bucket
  # solution : add force_destroy = true
  force_destroy = true
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id

  # AWS Console S3 : Bucket Versioning : Enabled
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  # AWS Console S3 : Encryption type : Server-side encryption with Amazon S3 managed keys (SSE-S3)
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  # AWS Console s3 : Block public access to buckets and objects granted through new access control lists (ACLs)
  block_public_acls = true
  # AWS Console s3 : Block public access to buckets and objects granted through any access control lists (ACLs)
  ignore_public_acls = true
  # AWS Console s3 : Block public access to buckets and objects granted through new public bucket or access point policies
  block_public_policy = true
  # AWS Console s3 : Block public and cross-account access to buckets and objects through any public bucket or access point policies
  restrict_public_buckets = true

  /*
    https://stackoverflow.com/questions/64303953/what-does-these-settings-mean-for-block-public-access-settings-in-s3

    1. BlockPublicAcls :
    This prevents any new ACLs to be created or existing ACLs being modified which enable public access to the object.
    With this alone existing ACLs will not be affected.
    
    2. IgnorePublicAcls :
    Any ACLs actions that exist with public access will be ignored, 
    this does not prevent them being created but prevents their effects.
    
    3. BlockPublicPolicy :
    This prevents a bucket policy containing public actions from being created or modified on an S3 bucket, 
    the bucket itself will still allow the existing policy.

    4. RestrictPublicBuckets :
    This will prevent non AWS services or authorized users (such as an IAM user or role) 
    from being able to publicly access objects in the bucket.
  */
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Partial Configuration. 
# The other settings will be passed in from a file via -backend-config arguments to 'terraform init'
# terraform {
#   backend "s3" {
#     key = "exmaple/terraform.tfstate"
#   }
# }

