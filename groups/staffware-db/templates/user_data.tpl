#!/bin/bash
# Redirect the user-data output to the console logs
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#Update Nagios registration script with relevant template
cp /usr/local/bin/nagios-host-add.sh /usr/local/bin/nagios-host-add.j2
REPLACE=${APPLICATION_NAME}_${ENVIRONMENT} /usr/local/bin/j2 /usr/local/bin/nagios-host-add.j2 > /usr/local/bin/nagios-host-add.sh

#Run Ansible playbook for deployment using provided inputs
cat <<EOF >inputs.json
${ANSIBLE_INPUTS}
EOF
/usr/local/bin/ansible-playbook /root/deployment.yml -e "@inputs.json"
