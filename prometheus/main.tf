resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "oci://ghcr.io/prometheus-community/charts/"
  chart            = "prometheus"
  namespace        = var.namespace
  version          = var.prometheus_chart_version
  create_namespace = true

  values = [
    templatefile("${path.module}/yaml/${var.environment}/prometheus-values.yaml", {
      region                   = var.aws_region
      environment              = var.environment
      cluster_name             = var.cluster_name
      service_account_role_arn = var.service_account_role_arn
    })
  ]

  depends_on = [
    kubernetes_persistent_volume_claim.prometheus_pvc,
  ]
}

resource "helm_release" "prometheus_crds" {
  name       = "prometheus-operator-crds"
  repository = "oci://ghcr.io/prometheus-community/charts/"
  chart      = "prometheus-operator-crds"
  namespace  = var.namespace
  version    = var.prometheus_crds_chart_version

  values = [
    templatefile("${path.module}/yaml/${var.environment}/prometheus-crds-values.yaml", {
      region                   = var.aws_region
      environment              = var.environment
      cluster_name             = var.cluster_name
      service_account_role_arn = var.service_account_role_arn
    })
  ]
}