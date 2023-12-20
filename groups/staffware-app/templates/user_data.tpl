#!/bin/bash
# Redirect the user-data output to the console logs
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#Update Nagios registration script with relevant template
cp /usr/local/bin/nagios-host-add.sh /usr/local/bin/nagios-host-add.j2
REPLACE=${APPLICATION}_${HERITAGE_ENVIRONMENT} /usr/local/bin/j2 /usr/local/bin/nagios-host-add.j2 > /usr/local/bin/nagios-host-add.sh

GET_PARAM_COMMAND="aws ssm get-parameter --with-decryption --region ${REGION} --output text --query Parameter.Value --name"

#Use provided inputs to create final tnsnames.ora file
$${GET_PARAM_COMMAND} '${TNSNAMES_INPUTS_PATH}' > tnsnames.json
/usr/local/bin/j2 -f json /home/swenvp1/tnsnames.j2 tnsnames.json > /app/oracle/product/19c/network/admin/tnsnames.ora

#Use provided inputs to create final staff.dat file
$${GET_PARAM_COMMAND} '${STAFF_DAT_INPUTS_PATH}' > staff_dat.json
/usr/local/bin/j2 -f json /home/swenvp1/staff_dat.j2 staff_dat.json > /app/iProcess/11_8/staff.dat

#Run Ansible playbook for app deployment using provided inputs
$${GET_PARAM_COMMAND} '${DEPLOYMENT_ANSIBLE_INPUTS_PATH}' > deployment.json
/usr/local/bin/ansible-playbook /root/deployment.yml -e "@deployment.json"

#Run DNS Update script with inputs
FQDN=`cat deployment.json | jq -r '"\(.HOSTNAME).\(.DOMAIN)"'`
sh /root/updatedns.sh ${R53_ZONEID} $FQDN