# test-aws

## create, list, run container local
- [ ] $ docker build -t test-aws .
- [ ] $ docker images
- [ ] $ docker run -p 80:3000 <id>

## create Amazon ECR, ...

## deploy.sh
- windown run in ternimal shell WSL
- [ ]  sudo snap install aws-cli --classic

<!-- https://us-east-1.console.aws.amazon.com/iam/home#/security_credentials -->
- [ ]  config: sudo aws configure

- [ ]  jq: sudo snap install jq  # version 1.5+dfsg-1
- [ ]  docker: sudo apt install docker.io / sudo systemctl start docker
- [ ]  link to path folder project: cd /mnt/d/job/test-aws

## Login to ECR with id pass in deploy.sh
- [ ]  sudo docker login https://registry-1.docker.io/v2/
- [ ]  sudo ./deploy.sh

## List Subnets / Security Groups
- aws ec2 describe-subnets --region us-east-2
- aws ec2 describe-security-groups --region us-east-2

<!-- terraform -->
