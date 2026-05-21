output "grafana_namespace" {
  description = "Namespace Kubernetes onde o Grafana está implantado"
  value       = kubernetes_namespace.grafana.metadata[0].name
}

output "loki_s3_role_arn" {
  description = "ARN da IAM role usada pelo Loki para acessar os buckets S3"
  value       = aws_iam_role.loki.arn
}

output "loki_chunks_bucket_name" {
  description = "Nome do bucket S3 usado para chunks de logs do Loki"
  value       = aws_s3_bucket.loki_chunks.bucket
}

output "loki_ruler_bucket_name" {
  description = "Nome do bucket S3 usado para regras do Loki"
  value       = aws_s3_bucket.loki_ruler.bucket
}

output "loki_admin_bucket_name" {
  description = "Nome do bucket S3 usado para dados admin do Loki"
  value       = aws_s3_bucket.loki_admin.bucket
}

output "grafana_efs_id" {
  description = "ID do EFS usado para armazenamento persistente do Grafana (apenas produção)"
  value       = var.environment == "prod" ? aws_efs_file_system.grafana_efs[0].id : null
}

output "grafana_role_arn" {
  description = "ARN da IAM role do Grafana para acesso ao CloudWatch (apenas produção)"
  value       = var.environment == "prod" ? aws_iam_role.grafana_role[0].arn : null
}

output "grafana_cross_account_role_arn" {
  description = "ARN da IAM role cross-account para acesso ao Grafana (ambientes não-produção)"
  value       = var.environment != "prod" && var.grafana_role_arn != "" ? aws_iam_role.grafana_cross_account_role[0].arn : null
}