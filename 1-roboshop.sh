#!/bin/bash

AMI=ami-03265a0778a880afb #Amazon Machine Image (AMI) ID, here we used:Centos-8-DevOps-Practice, PASSWORD:DevOps321
SG_ID=sg-021ca03b1fe657511 #Security group ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web")
ZONE_ID=Z052856235HX3UDODIJ0R
DOMAIN_NAME="projoy.store"

for i in "${INSTANCES[@]}"
do
 # Check if instance exists
 INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$i" --query 'Reservations[].Instances[].InstanceId' --output text)
 if [ -z "$INSTANCE_ID" ] 
 then
     # Instance does not exist, create it
     if [ $i == "monodb" ] || [ $i == "mysql" ] || [ $i == "shipping" ]
     then
         INSTANCES_TYPE="t3.small"
     else
         INSTANCES_TYPE="t2.micro"
     fi

     if [ $i == "web" ]
     then
         # For "web" instance, get public IP
         IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].PublicIpAddress' --output text)
     else
         # For all other instances, get private IP
         IP_ADDRESS=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCES_TYPE --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text)
     fi

     echo "$i: $IP_ADDRESS"

     #create R53 record, make sure you delete existing record
     aws route53 change-resource-record-sets \
     --hosted-zone-id $ZONE_ID \
     --change-batch '
     {
         "Comment": "Creating a record set for cognito endpoint"
         ,"Changes": [{
         "Action"            : "UPSERT" 
         ,"ResourceRecordSet" : {
             "Name"            : "'$i'.'$DOMAIN_NAME'"
             ,"Type"           : "A"
             ,"TTL"            : 1
             ,"ResourceRecords" : [{
                "Value"       : "'$IP_ADDRESS'"
             }]
         }
         }]
     }
         '
 else
     # Instance exists, skip creation
     echo "$i instance already exists, skipping creation."
 fi
done
