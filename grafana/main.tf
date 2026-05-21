resource "kubernetes_namespace" "grafana" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}

resource "helm_release" "grafana" {
  count      = var.environment == "prod" ? 1 : 0
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "grafana"
  namespace  = var.namespace
  version    = var.grafana_chart_version

  values = [
    templatefile("${path.module}/yaml/${var.environment}/grafana-values.yaml", {
      region                   = var.aws_region
      environment              = var.environment
      cluster_name             = var.cluster_name
      service_account_role_arn = var.service_account_role_arn
      db_host                  = var.db_host
      smtp_host                = var.smtp_host
      smtp_from_address        = var.smtp_from_address
      grafana_root_url         = var.grafana_root_url
    })
  ]

  depends_on = [
    kubernetes_namespace.grafana,
    kubernetes_manifest.grafana_secret,
    kubernetes_persistent_volume_claim.grafana_pvc,
    kubernetes_manifest.grafana_db_credentials_secret,
  ]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "loki"
  namespace  = var.namespace
  version    = var.loki_chart_version

  recreate_pods = true

  values = [
    templatefile("${path.module}/yaml/${var.environment}/loki-values.yaml", {
      cluster_name          = var.cluster_name
      environment           = var.environment
      aws_region            = var.aws_region
      aws_iam_role_loki_arn = aws_iam_role.loki.arn
    })
  ]

  depends_on = [
    kubernetes_namespace.grafana,
    aws_iam_role.loki,
  ]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "promtail"
  namespace  = var.namespace
  version    = var.promtail_chart_version

  values = [
    templatefile("${path.module}/yaml/${var.environment}/promtail-values.yaml", {
      loki_service_url = "http://loki-write.${var.namespace}.svc.cluster.local:3100/loki/api/v1/push"
    })
  ]

  depends_on = [
    helm_release.loki,
  ]
}