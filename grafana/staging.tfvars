environment  = "staging"
cluster_name = "my-eks-cluster-staging"
aws_profile  = "my-aws-profile-staging"
aws_region   = "us-east-1"
namespace    = "grafana"

service_account_role_arn = "arn:aws:iam::ACCOUNT_ID:role/grafana-role-staging"

vpc_name   = "my-vpc-staging"
kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/YOUR_KMS_KEY_ID"

private_subnet_ids = [
  "subnet-XXXXXXXXXXXXXXXXX",
  "subnet-XXXXXXXXXXXXXXXXX",
]

efs_security_group_ids = [
  "sg-XXXXXXXXXXXXXXXXX",
]

efs_posix_user_uid             = 1001
efs_posix_user_gid             = 1001
efs_root_directory_path        = "/grafana"
efs_root_directory_owner_uid   = 1001
efs_root_directory_owner_gid   = 1001
efs_root_directory_permissions = "0755"
pv_storage                     = "8Gi"
pvc_storage                    = "8Gi"

db_host           = ""
smtp_host         = ""
smtp_from_address = ""
grafana_root_url  = ""

grafana_hostname   = "grafana-staging.example.com"
loki_hostname      = "loki-staging.example.com"
ingress_class_name = "nginx"

grafana_role_arn = "arn:aws:iam::PROD_ACCOUNT_ID:role/grafana-role-PROD_CLUSTER_NAME"

tags = {
  Project     = "observability"
  Environment = "staging"
  ManagedBy   = "terraform"
}