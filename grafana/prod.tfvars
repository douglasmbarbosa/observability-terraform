environment  = "prod"
cluster_name = "my-eks-cluster-prod"
aws_profile  = "my-aws-profile-prod"
aws_region   = "us-east-1"
namespace    = "grafana"

service_account_role_arn = "arn:aws:iam::ACCOUNT_ID:role/grafana-role-CLUSTER_NAME"

db_host           = "your-db-host.rds.amazonaws.com:5432"
smtp_host         = "email-smtp.us-east-1.amazonaws.com:587"
smtp_from_address = "grafana@example.com"
grafana_root_url  = "https://grafana.example.com"

vpc_name   = "my-vpc-prod"
kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/YOUR_KMS_KEY_ID"

private_subnet_ids = [
  "subnet-XXXXXXXXXXXXXXXXX",
  "subnet-XXXXXXXXXXXXXXXXX",
]

efs_security_group_ids = [
  "sg-XXXXXXXXXXXXXXXXX",
  "sg-XXXXXXXXXXXXXXXXX",
]

efs_posix_user_uid             = 472
efs_posix_user_gid             = 472
efs_root_directory_path        = "/grafana"
efs_root_directory_owner_uid   = 472
efs_root_directory_owner_gid   = 472
efs_root_directory_permissions = "0775"
pv_storage                     = "20Gi"
pvc_storage                    = "8Gi"

grafana_hostname   = "grafana.example.com"
loki_hostname      = "loki.example.com"
ingress_class_name = "nginx"

cross_account_role_arns = {
  dev     = "arn:aws:iam::DEV_ACCOUNT_ID:role/grafana-cross-account-dev-CLUSTER_NAME"
  staging = "arn:aws:iam::STAGING_ACCOUNT_ID:role/grafana-cross-account-staging-CLUSTER_NAME"
}

tags = {
  Project     = "observability"
  Environment = "prod"
  ManagedBy   = "terraform"
}