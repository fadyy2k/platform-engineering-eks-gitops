resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint
  ]
}

locals {
  github_oidc_host = replace(aws_iam_openid_connect_provider.github_actions.url, "https://", "")
  plan_subjects = [
    "repo:${var.github_repository}:pull_request",
    "repo:${var.github_repository}:ref:refs/heads/main"
  ]
  apply_subjects = [for env in var.environments : "repo:${var.github_repository}:environment:${env}"]
}

data "aws_iam_policy_document" "github_plan_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.plan_subjects
    }
  }
}

data "aws_iam_policy_document" "github_apply_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.apply_subjects
    }
  }
}

resource "aws_iam_role" "github_plan" {
  name                 = "${var.project_name}-github-plan"
  assume_role_policy   = data.aws_iam_policy_document.github_plan_assume.json
  max_session_duration = 3600
}

resource "aws_iam_role" "github_apply" {
  name                 = "${var.project_name}-github-apply"
  assume_role_policy   = data.aws_iam_policy_document.github_apply_assume.json
  max_session_duration = 3600
}
