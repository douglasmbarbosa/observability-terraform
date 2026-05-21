# Observability Terraform

Módulo de infraestrutura como código (IaC) para provisionamento e configuração do stack de observabilidade no ambiente AWS EKS. Este projeto gerencia o deploy do **Prometheus** (métricas) e do **Grafana + Loki + Promtail** (visualização e logs) via Terraform + Helm.

---

## Índice

- [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Subprojeto: Prometheus](#subprojeto-prometheus)
- [Subprojeto: Grafana](#subprojeto-grafana)
- [Configuração por Ambiente](#configuração-por-ambiente)
- [Guia de Deploy](#guia-de-deploy)
- [Segurança](#segurança)
- [Observabilidade](#observabilidade)
- [Troubleshooting](#troubleshooting)

---

## Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EKS Cluster                          │
│                                                                 │
│  ┌──────────────────┐        ┌──────────────────────────────┐  │
│  │  Namespace:       │        │  Namespace: grafana           │  │
│  │  prometheus       │        │                              │  │
│  │                  │        │  ┌──────────┐  ┌──────────┐  │  │
│  │  ┌────────────┐  │◄───────┤  │ Grafana  │  │  Loki    │  │  │
│  │  │ Prometheus │  │        │  │ (prod)   │  │ (todos)  │  │  │
│  │  │  Server    │  │        │  └──────────┘  └──────────┘  │  │
│  │  └─────┬──────┘  │        │       ▲              ▲        │  │
│  │        │         │        │  ┌────┴──────────────┴────┐  │  │
│  │  ┌─────▼──────┐  │        │  │       Promtail         │  │  │
│  │  │  EFS PVC   │  │        │  │   (DaemonSet - todos)  │  │  │
│  │  └────────────┘  │        │  └────────────────────────┘  │  │
│  └──────────────────┘        └──────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     AWS Services                          │  │
│  │  EFS (Prometheus PV)  │  S3 (Loki chunks/ruler/admin)    │  │
│  │  KMS (Encryption)     │  IAM Roles (IRSA)                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Componentes

| Componente | Função | Namespace | Ambientes |
|-----------|--------|-----------|-----------|
| **Prometheus** | Coleta e armazenamento de métricas | `prometheus` | dev, staging, prod |
| **Prometheus Operator CRDs** | CRDs para ServiceMonitor, PodMonitor, etc. | `prometheus` | dev, staging, prod |
| **Grafana** | Visualização de métricas e logs | `grafana` | prod apenas |
| **Loki** | Agregação e armazenamento de logs | `grafana` | dev, staging, prod |
| **Promtail** | Coleta e envio de logs para Loki | `grafana` | dev, staging, prod |

---

## Pré-requisitos

### Ferramentas

| Ferramenta | Versão Mínima | Descrição |
|-----------|--------------|-----------|
| Terraform | >= 1.5.0 | IaC principal |
| AWS CLI | >= 2.x | Autenticação e acesso à AWS |
| kubectl | >= 1.28 | Interação com Kubernetes |
| Helm | >= 3.x | Gerenciamento de charts |

### Infraestrutura AWS

- **EKS Cluster** configurado e acessível
- **EFS CSI Driver** instalado no cluster (`aws-efs-csi-driver`)
- **StorageClass** `efs-sc` criada no cluster
- **NGINX Ingress Controller** instalado
- **KMS Key** para criptografia do EFS
- **Subnets privadas** para os mount targets do EFS
- **Security Groups** configurados para o EFS (porta 2049/NFS)
- **IAM OIDC Provider** configurado no EKS (para IRSA)

### Permissões IAM

O usuário/role que executa o Terraform precisa de permissões para:
- `efs:*` — Criar e gerenciar sistemas de arquivos EFS
- `s3:*` — Criar e gerenciar buckets S3 (Loki)
- `iam:*` — Criar roles e policies (IRSA)
- `kms:*` — Usar chaves KMS para criptografia
- `eks:DescribeCluster` — Obter informações do cluster

### Backends S3

Cada subprojeto usa um backend S3 separado. Certifique-se de que os buckets existam antes do primeiro `terraform init`.

---

## Estrutura do Projeto

```
observability-terraform/
├── README.md                          # Este arquivo
│
├── grafana/                           # Subprojeto Grafana + Loki + Promtail
│   ├── providers.tf                   # Configuração de providers e backend S3
│   ├── variables.tf                   # Declaração de todas as variáveis
│   ├── data.tf                        # Data sources (EKS cluster info)
│   ├── main.tf                        # Helm releases: Grafana, Loki, Promtail
│   ├── iam.tf                         # IAM roles para Grafana (IRSA, cross-account)
│   ├── s3-iam.tf                      # S3 buckets e IAM role para Loki
│   ├── pvc.tf                         # EFS, PV e PVC para Grafana (prod)
│   ├── manifests.tf                   # Kubernetes manifests (secrets, ingress)
│   ├── outputs.tf                     # Outputs do módulo
│   ├── dev.tfvars                     # Variáveis para ambiente dev
│   ├── staging.tfvars                 # Variáveis para ambiente staging
│   ├── prod.tfvars                    # Variáveis para ambiente prod
│   ├── dev.tfbackend                  # Configuração do backend S3 para dev
│   ├── staging.tfbackend              # Configuração do backend S3 para staging
│   ├── prod.tfbackend                 # Configuração do backend S3 para prod
│   └── yaml/
│       ├── dev/
│       │   ├── grafana-values.yaml    # Helm values do Grafana para dev
│       │   ├── grafana-ingress.yaml   # Ingress do Grafana para dev
│       │   ├── grafana-secret.yaml    # Secret de credenciais do Grafana
│       │   ├── grafana-secret-tls.yaml # Secret TLS para dev
│       │   ├── loki-values.yaml       # Helm values do Loki para dev
│       │   ├── loki-ingress.yaml      # Ingress do Loki para dev
│       │   └── promtail-values.yaml   # Helm values do Promtail para dev
│       ├── staging/
│       │   └── (mesma estrutura do dev)
│       └── prod/
│           ├── grafana-values.yaml    # Helm values do Grafana para prod
│           ├── grafana-ingress.yaml   # Ingress do Grafana para prod
│           ├── grafana-secret.yaml    # Secret de credenciais do Grafana
│           ├── grafana-secret-tls.yaml # Secret TLS para prod
│           ├── grafana-smtp-secret.yaml # Secret SMTP para notificações
│           ├── grafana-db-credentials-secret.yaml # Secret do banco PostgreSQL
│           ├── loki-values.yaml       # Helm values do Loki para prod
│           ├── loki-ingress.yaml      # Ingress do Loki para prod
│           └── promtail-values.yaml   # Helm values do Promtail para prod
│
└── prometheus/                        # Subprojeto Prometheus
    ├── providers.tf                   # Configuração de providers e backend S3
    ├── variables.tf                   # Declaração de todas as variáveis
    ├── data.tf                        # Data sources (EKS cluster info)
    ├── main.tf                        # Helm releases: Prometheus + CRDs
    ├── ingress.tf                     # Kubernetes manifests (TLS secret, ingress)
    ├── pvc.tf                         # EFS, PV e PVC para Prometheus
    ├── outputs.tf                     # Outputs do módulo
    ├── dev.tfvars                     # Variáveis para ambiente dev
    ├── staging.tfvars                 # Variáveis para ambiente staging
    ├── prod.tfvars                    # Variáveis para ambiente prod
    ├── dev.tfbackend                  # Configuração do backend S3 para dev
    ├── staging.tfbackend              # Configuração do backend S3 para staging
    ├── prod.tfbackend                 # Configuração do backend S3 para prod
    └── yaml/
        ├── dev/
        │   ├── prometheus-values.yaml      # Helm values do Prometheus para dev
        │   ├── prometheus-crds-values.yaml # Helm values dos CRDs para dev
        │   ├── prometheus-ingress.yaml     # Ingress do Prometheus para dev
        │   └── prometheus-secret-tls.yaml  # Secret TLS para dev
        ├── staging/
        │   └── (mesma estrutura do dev)
        └── prod/
            ├── prometheus-values.yaml      # Helm values do Prometheus para prod
            ├── prometheus-crds-values.yaml # Helm values dos CRDs para prod
            ├── prometheus-ingress.yaml     # Ingress do Prometheus para prod
            └── prometheus-secret-tls.yaml  # Secret TLS para prod
```

---

## Subprojeto: Prometheus

### Recursos Criados

| Recurso | Tipo | Descrição |
|---------|------|-----------|
| `aws_efs_file_system` | AWS | Sistema de arquivos EFS criptografado para dados do Prometheus |
| `aws_efs_mount_target` | AWS | Mount targets em cada subnet privada |
| `aws_efs_access_point` | AWS | Access point com POSIX user configurado |
| `kubernetes_persistent_volume` | K8s | PV backed pelo EFS via CSI driver |
| `kubernetes_persistent_volume_claim` | K8s | PVC para o Prometheus server |
| `helm_release.prometheus` | Helm | Stack completo do Prometheus |
| `helm_release.prometheus_crds` | Helm | CRDs do Prometheus Operator |
| `kubernetes_manifest.prometheus_tls_secret` | K8s | Secret TLS para o ingress |
| `kubernetes_manifest.prometheus_ingress` | K8s | Ingress com TLS termination |

### Variáveis Principais

| Variável | Obrigatória | Padrão | Descrição |
|----------|-------------|--------|-----------|
| `environment` | ✅ | — | Ambiente: `dev`, `staging` ou `prod` |
| `cluster_name` | ✅ | — | Nome do cluster EKS |
| `vpc_name` | ✅ | — | Nome da VPC para os mount targets EFS |
| `kms_key_id` | ✅ | — | ARN da KMS key para criptografia EFS |
| `private_subnet_ids` | ✅ | — | Lista de IDs de subnets privadas |
| `efs_security_group_ids` | ✅ | — | Lista de IDs de security groups para EFS |
| `prometheus_hostname` | ✅ | — | Hostname para o ingress |
| `prometheus_retention` | ❌ | `15d` | Período de retenção dos dados |
| `prometheus_cpu_limit` | ❌ | `2000m` | Limite de CPU |
| `prometheus_memory_limit` | ❌ | `4Gi` | Limite de memória |
| `service_account_role_arn` | ❌ | `""` | ARN da IAM role para IRSA |

### Outputs

| Output | Descrição |
|--------|-----------|
| `prometheus_namespace` | Namespace Kubernetes do Prometheus |
| `prometheus_efs_id` | ID do EFS criado |
| `prometheus_pv_name` | Nome do Persistent Volume |
| `prometheus_pvc_name` | Nome do Persistent Volume Claim |
| `prometheus_service_url` | URL interna do serviço (para datasource no Grafana) |

---

## Subprojeto: Grafana

### Recursos Criados

| Recurso | Tipo | Descrição |
|---------|------|-----------|
| `kubernetes_namespace` | K8s | Namespace `grafana` |
| `helm_release.grafana` | Helm | Grafana (apenas em `prod`) |
| `helm_release.loki` | Helm | Loki em modo distribuído (todos os ambientes) |
| `helm_release.promtail` | Helm | Promtail DaemonSet (todos os ambientes) |
| `aws_s3_bucket.loki_chunks` | AWS | Bucket S3 para chunks de logs do Loki |
| `aws_s3_bucket.loki_ruler` | AWS | Bucket S3 para regras do Loki |
| `aws_s3_bucket.loki_admin` | AWS | Bucket S3 para dados admin do Loki |
| `aws_iam_role.loki` | AWS | IAM role para o Loki acessar S3 (IRSA) |
| `aws_iam_role.grafana_role` | AWS | IAM role do Grafana para CloudWatch (prod) |
| `aws_iam_role.grafana_cross_account_role` | AWS | Role cross-account para acesso ao Grafana (non-prod) |
| `aws_efs_file_system.grafana_efs` | AWS | EFS para dados persistentes do Grafana (prod) |
| `kubernetes_persistent_volume` | K8s | PV backed pelo EFS (prod) |
| `kubernetes_persistent_volume_claim` | K8s | PVC para o Grafana (prod) |

### Comportamento por Ambiente

| Componente | dev | staging | prod |
|-----------|-----|---------|------|
| Grafana | ❌ | ❌ | ✅ |
| Loki | ✅ | ✅ | ✅ |
| Promtail | ✅ | ✅ | ✅ |
| EFS para Grafana | ❌ | ❌ | ✅ |
| IAM Role Grafana | ❌ | ❌ | ✅ |
| Cross-account Role | ✅ | ✅ | ❌ |
| PostgreSQL externo | ❌ | ❌ | ✅ |
| SMTP configurado | ❌ | ❌ | ✅ |

### Variáveis Principais

| Variável | Obrigatória | Padrão | Descrição |
|----------|-------------|--------|-----------|
| `environment` | ✅ | — | Ambiente: `dev`, `staging` ou `prod` |
| `cluster_name` | ✅ | — | Nome do cluster EKS |
| `vpc_name` | ✅ | — | Nome da VPC |
| `kms_key_id` | ✅ | — | ARN da KMS key |
| `private_subnet_ids` | ✅ | — | Subnets privadas |
| `efs_security_group_ids` | ✅ | — | Security groups para EFS |
| `grafana_hostname` | ✅ | — | Hostname do Grafana |
| `loki_hostname` | ✅ | — | Hostname do Loki |
| `db_host` | ❌ | `""` | Host do PostgreSQL (prod) |
| `smtp_host` | ❌ | `""` | Host SMTP para alertas (prod) |
| `grafana_root_url` | ❌ | `""` | URL pública do Grafana (prod) |
| `grafana_role_arn` | ❌ | `""` | ARN da role prod para cross-account |
| `cross_account_role_arns` | ❌ | `{}` | Map de roles cross-account |
| `loki_retention_period` | ❌ | `720h` | Retenção de logs no Loki |

### Outputs

| Output | Descrição |
|--------|-----------|
| `grafana_namespace` | Namespace Kubernetes do Grafana |
| `loki_s3_role_arn` | ARN da IAM role do Loki |
| `loki_chunks_bucket_name` | Nome do bucket S3 de chunks |
| `loki_ruler_bucket_name` | Nome do bucket S3 de ruler |
| `loki_admin_bucket_name` | Nome do bucket S3 de admin |
| `grafana_efs_id` | ID do EFS do Grafana (prod) |
| `grafana_role_arn` | ARN da IAM role do Grafana (prod) |
| `grafana_cross_account_role_arn` | ARN da role cross-account (non-prod) |

---

## Configuração por Ambiente

### Clusters EKS

| Ambiente | Cluster ARN |
|----------|-------------|
| dev | `arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev` |
| staging (hml) | `arn:aws:eks:<region>:<AWS_ACCOUNT_ID_STAGING>:cluster/eks-<project>-staging` |
| prod | `arn:aws:eks:<region>:<AWS_ACCOUNT_ID_PROD>:cluster/eks-<project>-prod` |

### Diferenças de Configuração

| Parâmetro | dev | staging | prod |
|-----------|-----|---------|------|
| Prometheus retention | 7d | 15d | 30d |
| Prometheus CPU limit | 500m | 1000m | 2000m |
| Prometheus Memory limit | 1Gi | 2Gi | 4Gi |
| Loki retention | 168h (7d) | 360h (15d) | 720h (30d) |
| PV Storage | 8Gi | 8Gi | 20Gi |
| Replicas Loki | 1 | 1 | 2 |
| HA / PodDisruptionBudget | ❌ | ❌ | ✅ |

---

## Guia de Deploy

### 1. Configurar Credenciais AWS

```bash
# Usando AWS CLI profiles (recomendado)
aws configure --profile <aws-profile-dev>

# Verificar acesso ao cluster
aws eks update-kubeconfig \
  --name eks-<project>-dev \
  --region <region> \
  --profile <aws-profile-dev>
```

### 2. Deploy do Prometheus

```bash
cd observability-terraform/prometheus

# Inicializar backend para o ambiente desejado
terraform init -backend-config=dev.tfbackend

# Verificar o plano de execução
terraform plan -var-file=dev.tfvars

# Aplicar as mudanças
terraform apply -var-file=dev.tfvars
```

### 3. Deploy do Grafana (Loki + Promtail)

```bash
cd observability-terraform/grafana

# Inicializar backend para o ambiente desejado
terraform init -backend-config=dev.tfbackend

# Verificar o plano de execução
terraform plan -var-file=dev.tfvars

# Aplicar as mudanças
terraform apply -var-file=dev.tfvars
```

### 4. Deploy em Staging

```bash
# Prometheus
cd observability-terraform/prometheus
terraform init -backend-config=staging.tfbackend -reconfigure
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars

# Grafana
cd observability-terraform/grafana
terraform init -backend-config=staging.tfbackend -reconfigure
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

### 5. Deploy em Produção

> ⚠️ **ATENÇÃO**: Sempre execute `terraform plan` e revise cuidadosamente antes de aplicar em produção.

```bash
# Verificar contexto kubectl antes de qualquer operação
kubectl config current-context
# Esperado: arn:aws:eks:<region>:<AWS_ACCOUNT_ID_PROD>:cluster/eks-<project>-prod

# Prometheus
cd observability-terraform/prometheus
terraform init -backend-config=prod.tfbackend -reconfigure
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

# Grafana
cd observability-terraform/grafana
terraform init -backend-config=prod.tfbackend -reconfigure
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### 6. Preparar Secrets Antes do Deploy

Antes de executar o Terraform, crie os secrets Kubernetes necessários:

```bash
# Secret TLS para Prometheus (substitua pelos certificados reais)
kubectl create secret tls prometheus-cert-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  --namespace=prometheus \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev

# Secret de credenciais do Grafana (prod)
kubectl create secret generic grafana-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<SENHA_SEGURA>' \
  --namespace=grafana \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_PROD>:cluster/eks-<project>-prod

# Secret de credenciais do banco de dados (prod)
kubectl create secret generic grafana-db-credentials \
  --from-literal=username=grafana \
  --from-literal=password='<DB_PASSWORD>' \
  --namespace=grafana \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_PROD>:cluster/eks-<project>-prod
```

### 7. Verificar o Deploy

```bash
# Verificar pods do Prometheus
kubectl get pods -n prometheus \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev

# Verificar pods do Grafana/Loki/Promtail
kubectl get pods -n grafana \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev

# Verificar ingresses
kubectl get ingress -n prometheus \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev

kubectl get ingress -n grafana \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev

# Verificar PVCs
kubectl get pvc -n prometheus \
  --context=arn:aws:eks:<region>:<AWS_ACCOUNT_ID_DEV>:cluster/eks-<project>-dev
```

---

## Segurança

### Princípios Aplicados

1. **IRSA (IAM Roles for Service Accounts)**: Nenhuma credencial AWS é hardcoded. O Prometheus e o Loki usam IAM roles vinculadas às service accounts do Kubernetes via OIDC.

2. **Criptografia em repouso**: O EFS é criptografado com KMS customer-managed key. Os buckets S3 do Loki também devem ter criptografia habilitada.

3. **Secrets Kubernetes**: Credenciais sensíveis (admin password, DB credentials, SMTP) são gerenciadas como Kubernetes Secrets, nunca como variáveis Terraform em texto plano.

4. **TLS obrigatório**: Todos os ingresses são configurados com TLS. Em produção, use certificados válidos (Let's Encrypt via cert-manager ou ACM).

5. **Autenticação no Prometheus**: Em produção, o ingress do Prometheus é protegido com basic auth para evitar exposição pública de métricas.

### Recomendações Adicionais

```bash
# Usar cert-manager para gerenciar certificados automaticamente
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# Criar ClusterIssuer para Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: devops@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Rotação de Secrets

```bash
# Rotacionar senha do Grafana
kubectl create secret generic grafana-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<NOVA_SENHA>' \
  --namespace=grafana \
  --dry-run=client -o yaml | kubectl apply -f -

# Reiniciar o pod para aplicar a nova senha
kubectl rollout restart deployment/grafana -n grafana
```

---

## Observabilidade

### Datasources no Grafana

Após o deploy, configure os datasources no Grafana:

1. **Prometheus** (métricas):
   - URL: `http://prometheus-server.prometheus.svc.cluster.local`
   - Obtida via output: `terraform output prometheus_service_url`

2. **Loki** (logs):
   - URL: `http://loki-read.grafana.svc.cluster.local:3100`

### Dashboards Recomendados

Importe os seguintes dashboards do Grafana.com:

| Dashboard | ID | Descrição |
|-----------|-----|-----------|
| Kubernetes Cluster | 7249 | Visão geral do cluster |
| Kubernetes Pods | 6781 | Métricas por pod |
| Node Exporter Full | 1860 | Métricas de nós |
| Loki Logs | 13639 | Exploração de logs |

### Alertas

Configure alertas no Prometheus usando `PrometheusRule` CRDs:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-alerts
  namespace: prometheus
spec:
  groups:
  - name: example
    rules:
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes > 1e9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Container {{ $labels.container }} usando muita memória"
```

---

## Troubleshooting

### Prometheus não inicia

```bash
# Verificar eventos do pod
kubectl describe pod -l app=prometheus-server -n prometheus

# Verificar se o PVC está bound
kubectl get pvc -n prometheus

# Verificar se o EFS está montado
kubectl exec -it <prometheus-pod> -n prometheus -- df -h
```

### Loki não consegue escrever no S3

```bash
# Verificar logs do Loki write
kubectl logs -l app.kubernetes.io/component=write -n grafana --tail=50

# Verificar se a service account tem a annotation correta
kubectl get sa loki -n grafana -o yaml | grep eks.amazonaws.com

# Testar permissões da IAM role
aws s3 ls s3://<loki-chunks-bucket> --profile <profile>
```

### Grafana não conecta ao banco de dados

```bash
# Verificar logs do Grafana
kubectl logs -l app.kubernetes.io/name=grafana -n grafana --tail=100

# Verificar se o secret do banco existe
kubectl get secret grafana-db-credentials -n grafana

# Testar conectividade com o banco
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n grafana -- \
  psql -h <db-host> -U grafana -d grafana
```

### Ingress não funciona

```bash
# Verificar se o ingress foi criado
kubectl get ingress -n prometheus
kubectl describe ingress prometheus-ingress -n prometheus

# Verificar logs do NGINX Ingress Controller
kubectl logs -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --tail=50

# Verificar se o secret TLS existe
kubectl get secret prometheus-cert-tls -n prometheus
```

### Resetar o estado do Terraform

```bash
# Remover um recurso do state sem destruir na AWS
terraform state rm 'helm_release.prometheus'

# Importar um recurso existente para o state
terraform import 'helm_release.prometheus' prometheus/prometheus
```

---

## Contribuindo

1. Sempre execute `terraform fmt` antes de commitar
2. Execute `terraform validate` para verificar a sintaxe
3. Use `terraform plan` para revisar mudanças antes de aplicar
4. Nunca commite arquivos `.tfstate` ou `.tfvars` com valores reais
5. Adicione novos ambientes criando os arquivos `.tfvars` e `.tfbackend` correspondentes

```bash
# Formatar código
terraform fmt -recursive

# Validar sintaxe
terraform validate

# Verificar segurança (requer tfsec)
tfsec .

# Verificar boas práticas (requer tflint)
tflint --recursive