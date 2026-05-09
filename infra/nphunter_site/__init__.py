"""nphunter.net static site — S3 + OAC + ACM + CloudFront."""

import json

import pulumi
from pulumi_aws import acm, cloudfront, route53, s3

from route53 import zone

DOMAIN = "nphunter.net"

bucket = s3.BucketV2(
    "nphunter-site-bucket",
    bucket="nphunter-site",
    tags={"Name": "nphunter-site", "Service": "nphunter-site"},
)

s3.BucketPublicAccessBlock(
    "nphunter-site-public-access-block",
    bucket=bucket.id,
    block_public_acls=True,
    block_public_policy=True,
    ignore_public_acls=True,
    restrict_public_buckets=True,
)

oac = cloudfront.OriginAccessControl(
    "nphunter-site-oac",
    name="nphunter-site-oac",
    origin_access_control_origin_type="s3",
    signing_behavior="always",
    signing_protocol="sigv4",
)

cert = acm.Certificate(
    "nphunter-site-cert",
    domain_name=DOMAIN,
    validation_method="DNS",
    tags={"Name": "nphunter-site-cert", "Service": "nphunter-site"},
)

cert_validation_record = route53.Record(
    "nphunter-site-cert-validation",
    zone_id=zone.zone_id,
    name=cert.domain_validation_options[0].resource_record_name,
    type=cert.domain_validation_options[0].resource_record_type,
    ttl=300,
    records=[cert.domain_validation_options[0].resource_record_value],
    allow_overwrite=True,
)

cert_validation = acm.CertificateValidation(
    "nphunter-site-cert-validation-wait",
    certificate_arn=cert.arn,
    validation_record_fqdns=[cert_validation_record.fqdn],
)

distribution = cloudfront.Distribution(
    "nphunter-site-cdn",
    enabled=True,
    is_ipv6_enabled=True,
    default_root_object="index.html",
    aliases=[DOMAIN],
    origins=[{
        "domain_name": bucket.bucket_regional_domain_name,
        "origin_id": "s3-nphunter-site",
        "origin_access_control_id": oac.id,
        "s3_origin_config": {"origin_access_identity": ""},
    }],
    default_cache_behavior={
        "target_origin_id": "s3-nphunter-site",
        "viewer_protocol_policy": "redirect-to-https",
        "allowed_methods": ["GET", "HEAD"],
        "cached_methods": ["GET", "HEAD"],
        "compress": True,
        # AWS-managed CachingOptimized policy
        "cache_policy_id": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    },
    custom_error_responses=[
        {
            "error_code": 403,
            "response_code": 404,
            "response_page_path": "/index.html",
        },
        {
            "error_code": 404,
            "response_code": 404,
            "response_page_path": "/index.html",
        },
    ],
    viewer_certificate={
        "acm_certificate_arn": cert_validation.certificate_arn,
        "ssl_support_method": "sni-only",
        "minimum_protocol_version": "TLSv1.2_2021",
    },
    restrictions={"geo_restriction": {"restriction_type": "none"}},
    price_class="PriceClass_100",
    tags={"Name": "nphunter-site-cdn", "Service": "nphunter-site"},
)

s3.BucketPolicy(
    "nphunter-site-bucket-policy",
    bucket=bucket.id,
    policy=pulumi.Output.all(bucket.arn, distribution.arn).apply(
        lambda args: json.dumps(
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "AllowCloudFrontOAC",
                        "Effect": "Allow",
                        "Principal": {"Service": "cloudfront.amazonaws.com"},
                        "Action": "s3:GetObject",
                        "Resource": f"{args[0]}/*",
                        "Condition": {"StringEquals": {"AWS:SourceArn": args[1]}},
                    }
                ],
            }
        )
    ),
)

root_record = route53.Record(
    "root-record",
    zone_id=zone.zone_id,
    name=DOMAIN,
    type="A",
    aliases=[{
        "name": distribution.domain_name,
        "zone_id": distribution.hosted_zone_id,
        "evaluate_target_health": False,
    }],
)

pulumi.export("nphunter_site_bucket", bucket.id)
pulumi.export("nphunter_site_distribution_id", distribution.id)
pulumi.export("nphunter_site_distribution_domain", distribution.domain_name)
pulumi.export("root_domain", root_record.fqdn)
