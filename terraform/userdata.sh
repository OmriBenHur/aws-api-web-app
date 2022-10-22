#!/bin/bash

yum update -y
amazon-linux-extras install docker

yum install git -y

systemctl start docker

systemctl enable docker


curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose
git clone https://github.com/OmriBenHur/aws-api-web-app.git
cd aws-api-web-app
chmod +x /usr/local/bin/docker-compose
chmod 666 /var/run/docker.sock
usermod -a -G docker ec2-user
export AWS_DEFAULT_REGION=us-east-1
docker-compose up -d
aws ssm get-parameter --name /tmdb-api-key --query 'Parameter.Value' | tr -d '"' > app/secret.py
