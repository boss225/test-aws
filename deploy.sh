#!/bin/bash

# Define variables (replace with your details)
IMAGE_NAME="test-aws"
CLUSTER_NAME="arn:aws:ecs:us-east-2:488347225713:cluster/test-aws-cluster"
SERVICE_NAME="test-aws-service"
PORT=3000  # Port for your Node.js application
REPOSITORY_URI="public.ecr.aws/u4u8z1j5"
IMAGE_TAG="latest"  # Define the image tag
SUBNET_IDS=("subnet-id-1" "subnet-id-2")  # Replace with your subnet IDs
SECURITY_GROUP_IDS=("security-group-id-1")  # Replace with your security group IDs

# Build the Docker image (replace with your build command)
docker build -t $IMAGE_NAME .

# Login to ECR (replace with your credentials if needed)
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin $REPOSITORY_URI

# Push the image to ECR
docker tag $IMAGE_NAME:$IMAGE_TAG $REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG
docker push $REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG

# Create/update ECS task definition
TASK_DEFINITION=$(aws ecs register-task-definition --family $SERVICE_NAME --network-mode awsvpc --cpu "256" --memory "512" --requires-compatibilities FARGATE --container-definitions "[{
    \"name\": \"$SERVICE_NAME\",
    \"image\": \"$REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG\",
    \"portMappings\": [{ \"containerPort\": $PORT }],
    \"essential\": true
}]" | jq -r '.taskDefinition.taskDefinitionArn')

# Prepare network configuration
NETWORK_CONFIGURATION=$(jq -n \
    --argjson subnets "$(printf '%s\n' "${SUBNET_IDS[@]}" | jq -R . | jq -s .)" \
    --argjson securityGroups "$(printf '%s\n' "${SECURITY_GROUP_IDS[@]}" | jq -R . | jq -s .)" \
    --arg assignPublicIp "DISABLED" \
    '{
        awsvpcConfiguration: {
            subnets: $subnets,
            securityGroups: $securityGroups,
            assignPublicIp: $assignPublicIp
        }
    }')

# Check if the service already exists
SERVICE_EXISTS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME | jq -r '.services | length')

if [ "$SERVICE_EXISTS" -eq 0 ]; then
  # Create ECS service
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_DEFINITION \
    --launch-type FARGATE \
    --desired-count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[\"${SUBNET_IDS[0]}\",\"${SUBNET_IDS[1]}\"],securityGroups=[\"${SECURITY_GROUP_IDS[0]}\"],assignPublicIp=\"DISABLED\"}"
else
  # Update ECS service
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_DEFINITION
fi

# Display service details (optional)
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME | jq

echo "Deployment completed!"
