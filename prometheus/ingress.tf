resource "kubernetes_manifest" "prometheus_tls_secret" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/prometheus-secret-tls.yaml"))

  depends_on = [
    helm_release.prometheus,
  ]
}

resource "kubernetes_manifest" "prometheus_ingress" {
  manifest = yamldecode(file("${path.module}/yaml/${var.environment}/prometheus-ingress.yaml"))

  depends_on = [
    helm_release.prometheus,
    kubernetes_manifest.prometheus_tls_secret,
  ]
}