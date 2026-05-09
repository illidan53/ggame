"""EC2 resources"""

import json

import pulumi
from pulumi_aws import ec2, iam

from ecr import registry_url, repository as ecr_repository
from security_group import sg
from vpc import public_subnet

config = pulumi.Config()
aws_config = pulumi.Config("aws")

region = aws_config.require("region")
certbot_email = config.require("certbot_email")
image_tag = config.require("image_tag")

# Amazon Linux 2023 AMI lookup
ami = ec2.get_ami(
    most_recent=True,
    owners=["amazon"],
    filters=[
        {"name": "name", "values": ["al2023-ami-2023.*-x86_64"]},
        {"name": "state", "values": ["available"]},
    ],
)

# IAM role for EC2 to pull images from ECR + Route53 access for certbot DNS-01
ec2_role = iam.Role("ggame-ec2-role",
    assume_role_policy=json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Effect": "Allow",
        }],
    }),
    tags={"Name": "ggame-ec2-role"},
)

ec2_policy = iam.RolePolicy("ggame-ec2-policy",
    role=ec2_role.id,
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
                    "ecr:DescribeImages",
                    "ecr:DescribeRepositories",
                    "ecr:GetDownloadUrlForLayer",
                ],
                "Resource": arn,
            },
            {
                "Effect": "Allow",
                "Action": ["route53:ListHostedZones", "route53:GetChange"],
                "Resource": "*",
            },
            {
                "Effect": "Allow",
                "Action": "route53:ChangeResourceRecordSets",
                "Resource": "arn:aws:route53:::hostedzone/Z05670062ZTWRSY6PDM7V",
            },
        ],
    })),
)

instance_profile = iam.InstanceProfile("ggame-ec2-profile",
    role=ec2_role.name,
)


USER_DATA_TEMPLATE = """#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== ggame user_data started at $(date) ==="

REGION="__REGION__"
DOMAIN_NAME="ggame.nphunter.net"
CERTBOT_EMAIL="__CERTBOT_EMAIL__"
IMAGE_URI="__REPOSITORY_URL__:__IMAGE_TAG__"
REGISTRY_URL="__REGISTRY_URL__"

echo "[INFO] Installing packages..."
dnf install -y docker nginx certbot python3-certbot-dns-route53 python3-certbot-nginx unzip

if ! command -v aws >/dev/null 2>&1; then
    echo "[INFO] Installing AWS CLI v2..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
fi

systemctl enable --now docker

cat > /usr/local/bin/deploy-ggame.sh << 'DEPLOY'
#!/bin/bash
set -euo pipefail

REGION="__REGION__"
IMAGE_URI="__REPOSITORY_URL__:__IMAGE_TAG__"
REGISTRY_URL="__REGISTRY_URL__"
CONTAINER_NAME="ggame"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pulling $IMAGE_URI"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY_URL"
docker pull "$IMAGE_URI"
PULLED_IMAGE_ID="$(docker image inspect --format '{{.Id}}' "$IMAGE_URI")"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    CURRENT_IMAGE_ID="$(docker inspect --format '{{.Image}}' "$CONTAINER_NAME" 2>/dev/null || true)"
    if [ -n "$CURRENT_IMAGE_ID" ] && [ "$CURRENT_IMAGE_ID" = "$PULLED_IMAGE_ID" ] && docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Image already current; keeping running container."
        exit 0
    fi
    docker rm -f "$CONTAINER_NAME"
fi

docker run \\
    --detach \\
    --name "$CONTAINER_NAME" \\
    --restart unless-stopped \\
    --publish 127.0.0.1:3000:3000 \\
    "$IMAGE_URI"

docker image prune -f
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ggame deployed."
DEPLOY
chmod +x /usr/local/bin/deploy-ggame.sh

cat > /etc/systemd/system/ggame-deploy.service << 'SERVICE'
[Unit]
Description=Pull and run the ggame Docker image
After=docker.service network-online.target
Wants=docker.service network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/deploy-ggame.sh
StandardOutput=append:/var/log/ggame-deploy.log
StandardError=append:/var/log/ggame-deploy.log
SERVICE

cat > /etc/systemd/system/ggame-deploy.timer << 'TIMER'
[Unit]
Description=Retry ggame Docker deployment every minute

[Timer]
OnBootSec=30
OnUnitActiveSec=60
Persistent=true

[Install]
WantedBy=timers.target
TIMER

# Move default nginx listener off port 80 to avoid conflict
sed -i 's/listen       80/listen       8080/' /etc/nginx/nginx.conf
sed -i 's/listen       \\[::\\]:80/listen       [::]:8080/' /etc/nginx/nginx.conf

cat > /etc/nginx/conf.d/ggame.conf << 'NGINX'
server {
    listen 80;
    server_name __DOMAIN_NAME__;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

systemctl enable --now nginx

echo "[INFO] Requesting Let's Encrypt certificate for $DOMAIN_NAME via Route53..."
if certbot certonly --dns-route53 -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "$CERTBOT_EMAIL"; then
    rm -f /etc/nginx/conf.d/ggame.conf
    cat > /etc/nginx/conf.d/ggame-ssl.conf << 'SSLNGINX'
server {
    listen 443 ssl;
    server_name __DOMAIN_NAME__;

    ssl_certificate /etc/letsencrypt/live/__DOMAIN_NAME__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__DOMAIN_NAME__/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name __DOMAIN_NAME__;
    return 301 https://$host$request_uri;
}
SSLNGINX
    nginx -t && systemctl reload nginx
    echo "[INFO] HTTPS configured."
else
    echo "[WARN] Certbot failed. HTTP proxy remains available while TLS is retried manually."
fi

systemctl enable --now certbot-renew.timer || true

systemctl daemon-reload
systemctl enable --now ggame-deploy.timer
systemctl start ggame-deploy.service || true

echo "=== ggame user_data completed at $(date) ==="
"""


DOMAIN_NAME = "ggame.nphunter.net"


def render_user_data(values: list[str]) -> str:
    repository_url, registry = values
    return (
        USER_DATA_TEMPLATE.replace("__REGION__", region)
        .replace("__DOMAIN_NAME__", DOMAIN_NAME)
        .replace("__CERTBOT_EMAIL__", certbot_email)
        .replace("__REPOSITORY_URL__", repository_url)
        .replace("__IMAGE_TAG__", image_tag)
        .replace("__REGISTRY_URL__", registry)
    )


user_data_script = pulumi.Output.all(ecr_repository.repository_url, registry_url).apply(render_user_data)

instance = ec2.Instance("ggame-ec2",
    instance_type="t3.medium",  # 2 vCPU, 4 GB RAM
    ami=ami.id,
    subnet_id=public_subnet.id,
    vpc_security_group_ids=[sg.id],
    associate_public_ip_address=False,
    key_name="slzhao-personal-mac",
    iam_instance_profile=instance_profile.name,
    user_data=user_data_script,
    user_data_replace_on_change=True,
    tags={"Name": "ggame-ec2"},
    opts=pulumi.ResourceOptions(ignore_changes=["ami"], depends_on=[ec2_policy]),
)

eip = ec2.Eip("ggame-eip",
    instance=instance.id,
    domain="vpc",
    tags={"Name": "ggame-eip"},
)

pulumi.export("instance_id", instance.id)
pulumi.export("instance_public_ip", eip.public_ip)
pulumi.export("image_uri", ecr_repository.repository_url.apply(lambda url: f"{url}:{image_tag}"))
