"""IAM resources — GitHub Actions OIDC roles for CI/CD"""

import json

import pulumi
from pulumi_aws import iam

from ecr import repository as ecr_repository
from nphunter_site import bucket as nphunter_bucket, distribution as nphunter_distribution
from s3 import bucket as artifacts_bucket

# Reference the existing GitHub OIDC provider
oidc_provider = iam.get_open_id_connect_provider(
    url="https://token.actions.githubusercontent.com",
)


def _trust_policy(repo: str) -> pulumi.Output:
    return pulumi.Output.all(oidc_provider.arn).apply(lambda args: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Federated": args[0]},
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": f"repo:{repo}:*"
                },
            },
        }],
    }))


# CI/CD role for ggame repo — S3 write (legacy) + ECR push (new path)
ggame_deploy_role = iam.Role("ggame-deploy-role",
    name="github-actions-ggame-deploy",
    assume_role_policy=_trust_policy("illidan53/ggame"),
    tags={"Name": "github-actions-ggame-deploy"},
)

iam.RolePolicy("ggame-deploy-s3-policy",
    role=ggame_deploy_role.id,
    policy=artifacts_bucket.arn.apply(lambda arn: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
            "Resource": [arn, f"{arn}/*"],
        }],
    })),
)

iam.RolePolicy("ggame-deploy-ecr-policy",
    role=ggame_deploy_role.id,
    policy=ecr_repository.arn.apply(lambda arn: json.dumps({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "ecr:GetAuthorizationToken",
                "Resource": "*",
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:BatchGetImage",
                    "ecr:CompleteLayerUpload",
                    "ecr:DescribeImages",
                    "ecr:DescribeRepositories",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:InitiateLayerUpload",
                    "ecr:PutImage",
                    "ecr:UploadLayerPart",
                ],
                "Resource": arn,
            },
        ],
    })),
)


# CI/CD role for nphunter-site repo — S3 sync + CloudFront invalidation
nphunter_site_deploy_role = iam.Role("nphunter-site-deploy-role",
    name="github-actions-nphunter-site-deploy",
    assume_role_policy=_trust_policy("illidan53/nphunter-site"),
    tags={"Name": "github-actions-nphunter-site-deploy"},
)

iam.RolePolicy("nphunter-site-deploy-s3-policy",
    role=nphunter_site_deploy_role.id,
    policy=nphunter_bucket.arn.apply(lambda arn: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket",
            ],
            "Resource": [arn, f"{arn}/*"],
        }],
    })),
)

iam.RolePolicy("nphunter-site-deploy-cloudfront-policy",
    role=nphunter_site_deploy_role.id,
    policy=nphunter_distribution.arn.apply(lambda arn: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution",
                "cloudfront:GetInvalidation",
                "cloudfront:ListInvalidations",
            ],
            "Resource": arn,
        }],
    })),
)


pulumi.export("ggame_deploy_role_arn", ggame_deploy_role.arn)
pulumi.export("nphunter_site_deploy_role_arn", nphunter_site_deploy_role.arn)
