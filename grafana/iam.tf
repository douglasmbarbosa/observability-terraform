resource "aws_iam_policy" "grafana_cloudwatch_policy" {
  count = var.environment == "prod" ? 1 : 0

  name        = "grafana-cloudwatch-policy-${var.cluster_name}"
  description = "Permite ao Grafana ler métricas e logs do CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:StopQuery",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource",
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "grafana-cloudwatch-policy-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role" "grafana_role" {
  count = var.environment == "prod" ? 1 : 0

  name = "grafana-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:grafana"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "grafana-role-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_attach" {
  count = var.environment == "prod" ? 1 : 0

  role       = aws_iam_role.grafana_role[0].name
  policy_arn = aws_iam_policy.grafana_cloudwatch_policy[0].arn
}

resource "aws_iam_policy" "grafana_assume_role_policy" {
  count = var.environment == "prod" && length(var.cross_account_role_arns) > 0 ? 1 : 0

  name        = "grafana-assume-cross-account-policy-${var.cluster_name}"
  description = "Permite ao Grafana de produção assumir roles em outras contas AWS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = values(var.cross_account_role_arns)
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "grafana-assume-cross-account-policy-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "grafana_assume_role_attach" {
  count = var.environment == "prod" && length(var.cross_account_role_arns) > 0 ? 1 : 0

  role       = aws_iam_role.grafana_role[0].name
  policy_arn = aws_iam_policy.grafana_assume_role_policy[0].arn
}

resource "aws_iam_policy" "grafana_cross_account_policy" {
  count = var.environment != "prod" && var.grafana_role_arn != "" ? 1 : 0

  name        = "grafana-cross-account-cloudwatch-${var.cluster_name}"
  description = "Permite ao Grafana de produção ler CloudWatch desta conta"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:StopQuery",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "grafana-cross-account-cloudwatch-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role" "grafana_cross_account_role" {
  count = var.environment != "prod" && var.grafana_role_arn != "" ? 1 : 0

  name = "grafana-cross-account-${var.environment}-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.grafana_role_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "grafana-cross-account-${var.environment}-${var.cluster_name}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cross_account_attach" {
  count = var.environment != "prod" && var.grafana_role_arn != "" ? 1 : 0

  role       = aws_iam_role.grafana_cross_account_role[0].name
  policy_arn = aws_iam_policy.grafana_cross_account_policy[0].arn
}