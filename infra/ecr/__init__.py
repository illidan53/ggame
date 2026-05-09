"""GGame ECR repository."""

import json

import pulumi
from pulumi_aws import ecr

repository = ecr.Repository(
    "ggame-repository",
    name="ggame",
    image_scanning_configuration={"scan_on_push": True},
    image_tag_mutability="MUTABLE",
    tags={"Name": "ggame-repository", "Service": "ggame"},
)

ecr.LifecyclePolicy(
    "ggame-repository-lifecycle",
    repository=repository.name,
    policy=json.dumps(
        {
            "rules": [
                {
                    "rulePriority": 1,
                    "description": "Keep the latest 10 tagged images",
                    "selection": {
                        "tagStatus": "tagged",
                        "tagPrefixList": ["latest", "release", "dev"],
                        "countType": "imageCountMoreThan",
                        "countNumber": 10,
                    },
                    "action": {"type": "expire"},
                },
                {
                    "rulePriority": 2,
                    "description": "Expire untagged images after 7 days",
                    "selection": {
                        "tagStatus": "untagged",
                        "countType": "sinceImagePushed",
                        "countUnit": "days",
                        "countNumber": 7,
                    },
                    "action": {"type": "expire"},
                },
            ]
        }
    ),
)

registry_url = repository.repository_url.apply(lambda url: url.split("/")[0])

pulumi.export("ecr_repository_name", repository.name)
pulumi.export("ecr_repository_url", repository.repository_url)
