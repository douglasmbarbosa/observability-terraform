resource "aws_efs_file_system" "grafana_efs" {
  count = var.environment == "prod" ? 1 : 0

  creation_token   = "grafana-efs-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  kms_key_id       = var.kms_key_id

  tags = merge(var.tags, {
    Name        = "grafana-efs-${var.environment}"
    Environment = var.environment
    Component   = "grafana"
  })
}

resource "aws_efs_mount_target" "grafana_efs_mount" {
  for_each = var.environment == "prod" ? toset(var.private_subnet_ids) : toset([])

  file_system_id  = aws_efs_file_system.grafana_efs[0].id
  subnet_id       = each.value
  security_groups = var.efs_security_group_ids
}

resource "aws_efs_access_point" "grafana_ap" {
  count = var.environment == "prod" ? 1 : 0

  file_system_id = aws_efs_file_system.grafana_efs[0].id

  posix_user {
    uid = var.efs_posix_user_uid
    gid = var.efs_posix_user_gid
  }

  root_directory {
    path = var.efs_root_directory_path

    creation_info {
      owner_uid   = var.efs_root_directory_owner_uid
      owner_gid   = var.efs_root_directory_owner_gid
      permissions = var.efs_root_directory_permissions
    }
  }

  tags = merge(var.tags, {
    Name        = "grafana-efs-ap-${var.environment}"
    Environment = var.environment
  })
}

resource "kubernetes_persistent_volume" "grafana_pv" {
  count = var.environment == "prod" ? 1 : 0

  metadata {
    name = "grafana-efs-pv-${var.environment}"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }

  spec {
    capacity = {
      storage = var.pv_storage
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "efs-sc"

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${aws_efs_file_system.grafana_efs[0].id}::${aws_efs_access_point.grafana_ap[0].id}"
      }
    }
  }

  depends_on = [aws_efs_mount_target.grafana_efs_mount]
}

resource "kubernetes_persistent_volume_claim" "grafana_pvc" {
  count = var.environment == "prod" ? 1 : 0

  metadata {
    name      = "grafana-efs-pvc-${var.environment}"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "efs-sc"

    resources {
      requests = {
        storage = var.pvc_storage
      }
    }

    volume_name = kubernetes_persistent_volume.grafana_pv[0].metadata[0].name
  }

  depends_on = [kubernetes_persistent_volume.grafana_pv]
}