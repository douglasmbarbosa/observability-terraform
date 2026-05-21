resource "kubernetes_manifest" "grafana_secret" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/grafana-secret.yaml"))

  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_manifest" "grafana_tls_secret" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/grafana-secret-tls.yaml"))

  depends_on = [
    kubernetes_namespace.grafana,
    helm_release.grafana,
  ]
}

resource "kubernetes_manifest" "grafana_ingress" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/grafana-ingress.yaml"))

  depends_on = [
    helm_release.grafana,
    kubernetes_manifest.grafana_tls_secret,
  ]
}

resource "kubernetes_manifest" "loki_ingress" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/loki-ingress.yaml"))

  depends_on = [
    helm_release.loki,
    kubernetes_manifest.grafana_tls_secret,
  ]
}

resource "kubernetes_manifest" "grafana_db_credentials_secret" {
  count = var.environment == "prod" && var.db_host != "" ? 1 : 0

  manifest = yamldecode(file("${path.module}/yaml/prod/grafana-db-credentials-secret.yaml"))

  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_manifest" "grafana_smtp_secret" {
  count = var.environment == "prod" && var.smtp_host != "" ? 1 : 0

  manifest = yamldecode(file("${path.module}/yaml/prod/grafana-smtp-secret.yaml"))

  depends_on = [kubernetes_namespace.grafana]
}