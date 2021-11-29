#!/bin/bash
# Redirect the user-data output to the console logs
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#Update Nagios registration script with relevant template
cp /usr/local/bin/nagios-host-add.sh /usr/local/bin/nagios-host-add.j2
REPLACE=${APPLICATION}_${HERITAGE_ENVIRONMENT} /usr/local/bin/j2 /usr/local/bin/nagios-host-add.j2 > /usr/local/bin/nagios-host-add.sh

#Use provided inputs to create final tnsnames.ora file
cat <<EOF >>tnsnames.json
${IPROCESS_TNS_INPUTS}
EOF
/usr/local/bin/j2 -f json /home/swenvp1/tnsnames.j2 tnsnames.json > /app/oracle/product/19c/network/admin/tnsnames.ora

#Run Ansible playbook for app deployment using provided inputs
cat <<EOF >deployment.json
${IPROCESS_APP_INPUTS}
EOF
/usr/local/bin/ansible-playbook /root/deployment.yml -e "@deployment.json"