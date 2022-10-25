#!/bin/bash

yum update -y

amazon-linux-extras install docker -y

yum install git -y

systemctl start docker

systemctl enable docker

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

git clone https://github.com/OmriBenHur/aws-api-web-app.git

cd aws-api-web-app

chmod +x /usr/local/bin/docker-compose

chmod 666 /var/run/docker.sock

usermod -a -G docker ec2-user

export AWS_DEFAULT_REGION=us-west-2

var="key = "

var+=$(aws secretsmanager get-secret-value --secret-id web-app/api-key --query 'SecretString' | cut -d ':' -f 2 | tr -d '\\}')

echo ${var%?} > app/secret.py

var=""

docker-compose up -d

