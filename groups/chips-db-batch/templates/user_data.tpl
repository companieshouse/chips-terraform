#!/bin/bash
# Redirect the user-data output to the console logs
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#Get application instance identifier from tags in AWS metadata service
EC2_INSTANCE_ID=$( ec2-metadata -i | awk '{print $2}' )
AVAILABILITY_ZONE=$( ec2-metadata -z | awk '{print $2}' )
EC2_REGION=$${AVAILABILITY_ZONE::-1}
APP_INSTANCE_NAME=$( aws ec2 describe-tags --filters "Name=resource-id,Values=$EC2_INSTANCE_ID" "Name=key,Values=app-instance-name"  --region $EC2_REGION | jq -r '.Tags[]//[]|select(.Key=="app-instance-name")|.Value' )

#Template application identifier into deployment playbook inputs
echo '${ANSIBLE_INPUTS}' | jq --arg APP_INSTANCE_NAME "$APP_INSTANCE_NAME"  'walk(if type == "object" and has("file_path") then .file_path |= sub("APPINSTANCENAME"; $APP_INSTANCE_NAME) else . end)' > /root/ansible_inputs.json

#Run Ansible playbook for server setup using provided inputs
/usr/local/bin/ansible-playbook /root/deployment.yml -e '@/root/ansible_inputs.json'

#Upsert a Route53 DNS record for this EC2 instance
/usr/local/bin/update-dns.sh ${DNS_ZONE_ID} "$APP_INSTANCE_NAME.${DNS_DOMAIN}"

#Run bootstrap script to download config from S3 and start Docker containers
su -l ec2-user bootstrap
