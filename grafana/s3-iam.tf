resource "aws_s3_bucket" "loki_chunks" {
  bucket = "loki-chunks-${var.cluster_name}"

  tags = merge(var.tags, {
    Name        = "loki-chunks-${var.cluster_name}"
    Environment = var.environment
    Component   = "loki"
  })
}

resource "aws_s3_bucket_versioning" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "loki_ruler" {
  bucket = "loki-ruler-${var.cluster_name}"

  tags = merge(var.tags, {
    Name        = "loki-ruler-${var.cluster_name}"
    Environment = var.environment
    Component   = "loki"
  })
}

resource "aws_s3_bucket_versioning" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "loki_admin" {
  bucket = "loki-admin-${var.cluster_name}"

  tags = merge(var.tags, {
    Name        = "loki-admin-${var.cluster_name}"
    Environment = var.environment
    Component   = "loki"
  })
}

resource "aws_s3_bucket_versioning" "loki_admin" {
  bucket = aws_s3_bucket.loki_admin.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_admin" {
  bucket = aws_s3_bucket.loki_admin.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki_admin" {
  bucket = aws_s3_bucket.loki_admin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "loki_s3" {
  name        = "loki-s3-policy-${var.cluster_name}"
  description = "Permite ao Loki ler e escrever nos buckets S3 de armazenamento"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = [
          "${aws_s3_bucket.loki_chunks.arn}/*",
          "${aws_s3_bucket.loki_ruler.arn}/*",
          "${aws_s3_bucket.loki_admin.arn}/*",
          aws_s3_bucket.loki_chunks.arn,
          aws_s3_bucket.loki_ruler.arn,
          aws_s3_bucket.loki_admin.arn,
        ]
      },
    ]
  })

  tags = merge(var.tags, {
    Name        = "loki-s3-policy-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role" "loki" {
  name = "loki-s3-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:loki-service-account"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "loki-s3-role-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "loki_s3" {
  role       = aws_iam_role.loki.name
  policy_arn = aws_iam_policy.loki_s3.arn
}