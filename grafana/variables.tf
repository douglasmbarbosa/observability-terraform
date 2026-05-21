variable "aws_region" {
  description = "Região AWS onde os recursos serão implantados"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil do AWS CLI para autenticação"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Nome do ambiente de implantação (dev, staging ou prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser um dos seguintes: dev, staging, prod."
  }
}

variable "cluster_name" {
  description = "Nome do cluster EKS onde o Grafana será implantado"
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes para Grafana, Loki e Promtail"
  type        = string
  default     = "grafana"
}

variable "grafana_chart_version" {
  description = "Versão do Helm chart do Grafana"
  type        = string
  default     = "10.3.0"
}

variable "loki_chart_version" {
  description = "Versão do Helm chart do Loki"
  type        = string
  default     = "6.46.0"
}

variable "promtail_chart_version" {
  description = "Versão do Helm chart do Promtail"
  type        = string
  default     = "6.15.5"
}

variable "service_account_role_arn" {
  description = "ARN da IAM role para a service account do Grafana (IRSA)"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Nome da VPC onde os mount targets do EFS serão criados"
  type        = string
}

variable "kms_key_id" {
  description = "ARN da KMS key usada para criptografar o EFS"
  type        = string
}

variable "private_subnet_ids" {
  description = "Lista de IDs de subnets privadas para os mount targets do EFS"
  type        = list(string)
}

variable "efs_security_group_ids" {
  description = "Lista de IDs de security groups para os mount targets do EFS"
  type        = list(string)
}

variable "efs_posix_user_uid" {
  description = "UID do usuário POSIX para o access point do EFS"
  type        = number
  default     = 472
}

variable "efs_posix_user_gid" {
  description = "GID do usuário POSIX para o access point do EFS"
  type        = number
  default     = 472
}

variable "efs_root_directory_path" {
  description = "Caminho do diretório raiz para o access point do EFS"
  type        = string
  default     = "/grafana"
}

variable "efs_root_directory_owner_uid" {
  description = "UID do proprietário do diretório raiz do access point do EFS"
  type        = number
  default     = 472
}

variable "efs_root_directory_owner_gid" {
  description = "GID do proprietário do diretório raiz do access point do EFS"
  type        = number
  default     = 472
}

variable "efs_root_directory_permissions" {
  description = "Permissões do diretório raiz do access point do EFS (formato octal)"
  type        = string
  default     = "0775"
}

variable "pv_storage" {
  description = "Capacidade de armazenamento do Persistent Volume do Grafana"
  type        = string
  default     = "20Gi"
}

variable "pvc_storage" {
  description = "Capacidade de armazenamento solicitada pelo Persistent Volume Claim do Grafana"
  type        = string
  default     = "8Gi"
}

variable "db_host" {
  description = "Hostname e porta do banco PostgreSQL externo para o Grafana (ex: 'db.example.com:5432')"
  type        = string
  default     = ""
}

variable "smtp_host" {
  description = "Host e porta do servidor SMTP para notificações por e-mail (ex: 'smtp.example.com:587')"
  type        = string
  default     = ""
}

variable "smtp_from_address" {
  description = "Endereço de e-mail usado como remetente nas notificações do Grafana"
  type        = string
  default     = ""
}

variable "grafana_root_url" {
  description = "URL pública da instância do Grafana (ex: 'https://grafana.example.com')"
  type        = string
  default     = ""
}

variable "grafana_role_arn" {
  description = "ARN da IAM role do Grafana de produção para acesso cross-account ao CloudWatch"
  type        = string
  default     = ""
}

variable "cross_account_role_arns" {
  description = "Mapa de nomes de ambiente para ARNs de IAM roles que o Grafana de produção pode assumir"
  type        = map(string)
  default     = {}
}

variable "loki_retention_period" {
  description = "Período de retenção de logs no Loki (ex: '720h' para 30 dias)"
  type        = string
  default     = "720h"
}

variable "loki_write_replicas" {
  description = "Número de réplicas para o componente de escrita do Loki"
  type        = number
  default     = 2
}

variable "loki_read_replicas" {
  description = "Número de réplicas para o componente de leitura do Loki"
  type        = number
  default     = 2
}

variable "loki_backend_replicas" {
  description = "Número de réplicas para o componente de backend do Loki"
  type        = number
  default     = 2
}

variable "grafana_cpu_limit" {
  description = "Limite de CPU para o container do Grafana"
  type        = string
  default     = "1000m"
}

variable "grafana_memory_limit" {
  description = "Limite de memória para o container do Grafana"
  type        = string
  default     = "1024Mi"
}

variable "grafana_cpu_request" {
  description = "Requisição de CPU para o container do Grafana"
  type        = string
  default     = "100m"
}

variable "grafana_memory_request" {
  description = "Requisição de memória para o container do Grafana"
  type        = string
  default     = "256Mi"
}

variable "grafana_hostname" {
  description = "Hostname para o Ingress do Grafana"
  type        = string
}

variable "loki_hostname" {
  description = "Hostname para o Ingress do Loki"
  type        = string
}

variable "ingress_class_name" {
  description = "Nome da classe de Ingress a ser usada"
  type        = string
  default     = "nginx"
}

variable "tags" {
  description = "Tags adicionais para aplicar a todos os recursos AWS"
  type        = map(string)
  default     = {}
}