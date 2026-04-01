# Remote state stored in S3 with DynamoDB locking.
# Run scripts/bootstrap-state.sh first to create the bucket and table.
terraform {
  backend "s3" {
    # Override these with -backend-config flags or a backend.hcl file:
    #   terraform init -backend-config="bucket=tfstate-eks-platform-123456789"
    bucket         = "tfstate-eks-platform-REPLACE_ME"
    key            = "eks-platform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
