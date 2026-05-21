output "prometheus_namespace" {
  description = "Namespace Kubernetes onde o Prometheus está implantado"
  value       = var.namespace
}

output "prometheus_efs_id" {
  description = "ID do EFS usado para armazenamento persistente do Prometheus"
  value       = aws_efs_file_system.prometheus_efs.id
}

output "prometheus_pv_name" {
  description = "Nome do Persistent Volume do Prometheus"
  value       = kubernetes_persistent_volume.prometheus_pv.metadata[0].name
}

output "prometheus_pvc_name" {
  description = "Nome do Persistent Volume Claim do Prometheus"
  value       = kubernetes_persistent_volume_claim.prometheus_pvc.metadata[0].name
}

output "prometheus_service_url" {
  description = "URL interna do serviço Prometheus (para uso como datasource no Grafana)"
  value       = "http://prometheus-server.${var.namespace}.svc.cluster.local"
}