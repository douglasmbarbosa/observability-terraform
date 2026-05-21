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
  description = "Nome do cluster EKS onde o Prometheus será implantado"
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes para o Prometheus"
  type        = string
  default     = "prometheus"
}

variable "prometheus_chart_version" {
  description = "Versão do Helm chart do Prometheus"
  type        = string
  default     = "27.46.0"
}

variable "prometheus_crds_chart_version" {
  description = "Versão do Helm chart dos CRDs do Prometheus Operator"
  type        = string
  default     = "25.0.0"
}

variable "service_account_role_arn" {
  description = "ARN da IAM role para a service account do Prometheus (IRSA)"
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
  default     = 1001
}

variable "efs_posix_user_gid" {
  description = "GID do usuário POSIX para o access point do EFS"
  type        = number
  default     = 1001
}

variable "efs_root_directory_path" {
  description = "Caminho do diretório raiz para o access point do EFS"
  type        = string
  default     = "/prometheus"
}

variable "efs_root_directory_owner_uid" {
  description = "UID do proprietário do diretório raiz do access point do EFS"
  type        = number
  default     = 1001
}

variable "efs_root_directory_owner_gid" {
  description = "GID do proprietário do diretório raiz do access point do EFS"
  type        = number
  default     = 1001
}

variable "efs_root_directory_permissions" {
  description = "Permissões do diretório raiz do access point do EFS (formato octal)"
  type        = string
  default     = "0755"
}

variable "pv_storage" {
  description = "Capacidade de armazenamento do Persistent Volume do Prometheus"
  type        = string
  default     = "20Gi"
}

variable "pvc_storage" {
  description = "Capacidade de armazenamento solicitada pelo Persistent Volume Claim do Prometheus"
  type        = string
  default     = "8Gi"
}

variable "prometheus_hostname" {
  description = "Hostname para o Ingress do Prometheus"
  type        = string
}

variable "ingress_class_name" {
  description = "Nome da classe de Ingress a ser usada"
  type        = string
  default     = "nginx"
}

variable "prometheus_retention" {
  description = "Período de retenção dos dados do Prometheus (ex: '15d', '30d')"
  type        = string
  default     = "15d"
}

variable "prometheus_cpu_limit" {
  description = "Limite de CPU para o container do Prometheus"
  type        = string
  default     = "2000m"
}

variable "prometheus_memory_limit" {
  description = "Limite de memória para o container do Prometheus"
  type        = string
  default     = "4Gi"
}

variable "prometheus_cpu_request" {
  description = "Requisição de CPU para o container do Prometheus"
  type        = string
  default     = "500m"
}

variable "prometheus_memory_request" {
  description = "Requisição de memória para o container do Prometheus"
  type        = string
  default     = "1Gi"
}

variable "tags" {
  description = "Tags adicionais para aplicar a todos os recursos AWS"
  type        = map(string)
  default     = {}
}