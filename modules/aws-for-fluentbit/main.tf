module "helm_addon" {
  source            = "../helm-addon"
  manage_via_gitops = var.manage_via_gitops
  set_values        = local.set_values
  helm_config       = local.helm_config
  irsa_config       = local.irsa_config
  addon_context     = var.addon_context
}

resource "aws_cloudwatch_log_group" "aws_for_fluent_bit" {
  count             = var.create_cw_log_group ? 1 : 0
  name              = local.log_group_name
  retention_in_days = var.cw_log_group_retention
  kms_key_id        = var.cw_log_group_kms_key_arn
  skip_destroy      = var.cw_log_group_skip_destroy
  tags              = var.addon_context.tags
}

resource "aws_iam_policy" "aws_for_fluent_bit" {
  name        = "${var.addon_context.eks_cluster_id}-fluentbit"
  description = "IAM Policy for AWS for FluentBit"
  policy      = data.aws_iam_policy_document.irsa.json
  tags        = var.addon_context.tags
}

data "aws_iam_policy_document" "irsa" {
  statement {
    sid       = "PutLogEvents"
    effect    = "Allow"
    resources = ["arn:${var.addon_context.aws_partition_id}:logs:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:log-group:*:log-stream:*"]
    actions   = ["logs:PutLogEvents"]
  }

  statement {
    sid       = "CreateCWLogs"
    effect    = "Allow"
    resources = ["arn:${var.addon_context.aws_partition_id}:logs:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:log-group:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
    ]
  }
}
