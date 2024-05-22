#!/bin/bash

# Define variables (replace with your details)
IMAGE_NAME="test-aws"
REGION="us-east-2"  # Ensure this matches your ECS cluster's region
CLUSTER_NAME="test-aws-cluster"  # Only use the cluster name here, not the ARN
SERVICE_NAME="test-aws-service"
PORT=3000  # Port for your Node.js application
REPOSITORY_URI="public.ecr.aws/u4u8z1j5"
IMAGE_TAG="latest"
SUBNET_ID="subnet-05544ac680d0cd232"  # Replace with your subnet ID
SECURITY_GROUP_ID="sg-0b2658ca737af119a"  # Replace with your security group ID

# Build the Docker image (replace with your build command)
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# Login to ECR Public (use the global endpoint)
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin $REPOSITORY_URI

# Push the image to ECR Public
docker tag $IMAGE_NAME:$IMAGE_TAG $REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG
docker push $REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG

# Create/update ECS task definition
TASK_DEFINITION=$(aws ecs register-task-definition --region $REGION --family $SERVICE_NAME --network-mode awsvpc --cpu "256" --memory "512" --requires-compatibilities FARGATE --container-definitions "[{
    \"name\": \"$SERVICE_NAME\",
    \"image\": \"$REPOSITORY_URI/$IMAGE_NAME:$IMAGE_TAG\",
    \"portMappings\": [{ \"containerPort\": $PORT }],
    \"essential\": true
}]" | jq -r '.taskDefinition.taskDefinitionArn')

# Check if the service exists
SERVICE_EXISTS=$(aws ecs describe-services --region $REGION --cluster $CLUSTER_NAME --services $SERVICE_NAME | jq -r '.services | length')

if [ "$SERVICE_EXISTS" -eq 0 ]; then
    # Create ECS service if it does not exist
    aws ecs create-service --region $REGION --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --task-definition $TASK_DEFINITION --launch-type FARGATE --desired-count 1 --network-configuration "{
        \"awsvpcConfiguration\": {
            \"subnets\": [\"$SUBNET_ID\"],
            \"securityGroups\": [\"$SECURITY_GROUP_ID\"],
            \"assignPublicIp\": \"ENABLED\"
        }
    }"
else
    # Update ECS service if it exists
    aws ecs update-service --region $REGION --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $TASK_DEFINITION
fi

# Display service details (optional)
aws ecs describe-services --region $REGION --cluster $CLUSTER_NAME --services $SERVICE_NAME | jq

echo "Deployment completed!"
