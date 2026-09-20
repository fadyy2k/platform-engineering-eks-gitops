locals {
  state_object_arn = "${aws_s3_bucket.terraform_state.arn}/*"
  project_role_arns = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
  ]
  project_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-*"
  ]
}

data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = [aws_s3_bucket.terraform_state.arn]
  }

  statement {
    sid    = "ReadWriteStateAndLocks"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [local.state_object_arn]
  }

  statement {
    sid    = "UseStateKmsKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.terraform_state.arn]
  }
}

data "aws_iam_policy_document" "plan_readonly" {
  statement {
    sid    = "ReadPlatformResources"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcs",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:DescribeUpdate",
      "eks:ListAccessEntries",
      "eks:ListAccessPolicies",
      "eks:ListAddons",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListClusters",
      "eks:ListNodegroups",
      "eks:ListTagsForResource",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "kms:DescribeKey",
      "kms:ListAliases",
      "kms:ListResourceTags",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "apply_platform" {
  statement {
    sid    = "ManageVpcAndComputeNetwork"
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateNetworkAclEntry",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteNatGateway",
      "ec2:DeleteNetworkAclEntry",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcs",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateAddress",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyLaunchTemplate",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceNetworkAclAssociation",
      "ec2:ReplaceNetworkAclEntry",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageEks"
    effect = "Allow"
    actions = [
      "eks:AssociateAccessPolicy",
      "eks:CreateAccessEntry",
      "eks:CreateAddon",
      "eks:CreateCluster",
      "eks:CreateNodegroup",
      "eks:DeleteAccessEntry",
      "eks:DeleteAddon",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:DescribeUpdate",
      "eks:DisassociateAccessPolicy",
      "eks:ListAccessEntries",
      "eks:ListAccessPolicies",
      "eks:ListAddons",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListClusters",
      "eks:ListNodegroups",
      "eks:ListTagsForResource",
      "eks:ListUpdates",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:UpdateAccessEntry",
      "eks:UpdateAddon",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageProjectIamRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = local.project_role_arns
  }

  statement {
    sid    = "ManageProjectIamPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = local.project_policy_arns
  }

  statement {
    sid       = "PassProjectRolesToEks"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = local.project_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "eks.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "CreateEksServiceLinkedRoles"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "eks.amazonaws.com",
        "eks-nodegroup.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "CreateTaggedEksKmsKeys"
    effect    = "Allow"
    actions   = ["kms:CreateKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid    = "ManageTaggedEksKmsKeys"
    effect = "Allow"
    actions = [
      "kms:CancelKeyDeletion",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:DisableKeyRotation",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListGrants",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:RevokeGrant",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  statement {
    sid    = "ManageProjectEksKmsAliases"
    effect = "Allow"
    actions = [
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:UpdateAlias"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:alias/eks/${var.project_name}-*",
      "arn:${data.aws_partition.current.partition}:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
    ]
  }

  statement {
    sid    = "ManageEksControlPlaneLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DeleteRetentionPolicy",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.project_name}-*:*"
    ]
  }

  statement {
    sid    = "ReadSupportingServices"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "kms:DescribeKey",
      "kms:ListAliases",
      "kms:ListResourceTags",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_plan_state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy" "github_plan_readonly" {
  name   = "platform-readonly"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.plan_readonly.json
}

resource "aws_iam_role_policy" "github_apply_state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_apply.id
  policy = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy" "github_apply_platform" {
  name   = "platform-apply"
  role   = aws_iam_role.github_apply.id
  policy = data.aws_iam_policy_document.apply_platform.json
}
