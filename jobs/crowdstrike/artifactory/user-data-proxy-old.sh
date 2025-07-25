#!/bin/bash

ROLE="cicd-k8-artifactory-proxy"              # chef role
POOL="laggar"
SWIMLANE="p"               # Use "p" for pool level services

#ENV_ROLE="$ROLE-$STAGE"      # (optional) - add an environment role
#PS_ROLE="some_sidecar_role"  # (optional) - defaults to $ROLE
#PS_CLUSTER="$POOL"           # (optional) - defaults to $POOL

####################################
## No user serviceable parts below #
####################################

STAGE="csgov"
PS_ENV=$STAGE
PS_CLUSTER=${PS_CLUSTER:-$POOL}
PS_ROLE=${PS_ROLE:-$ROLE}
CHEF_VALIDATOR="falcon-validator"
CHEF_ENV=$STAGE

NODE_ID=$(ec2metadata --instance-id)
REGION=$(ec2metadata --availability-zone | sed s/.$//)
RUNLIST="\"role[$ROLE]\""
if [[ $ENV_ROLE ]]; then RUNLIST="\"role[$ROLE]\", \"role[$ENV_ROLE]\""; fi

CHEF_NODE_NAME="${ROLE}-${NODE_ID}-${POOL}-${SWIMLANE}"
CHEF_SERVER="chef.eagle.eyrie.cloud"

mkdir /etc/chef/
cat <<NOVALIDATE > /etc/chef/first-boot.json
{
    "csdns": {
      "stage": "$STAGE"
    },
    "security_baseline": {
      "rpfilter": 1
    },
  "run_list": [
    "role[$ROLE]"
  ],
  "csbase": {
    "enable_fips": false
  },
  "ubuntu_pro": {
    "register": false
  },
  "infra_proxy": { "url": "http://infra-proxy.eagle.eyrie.cloud:3128" }
}
NOVALIDATE

cat <<EOP >/etc/chef/client.rb
chef_server_url         "https://$CHEF_SERVER/organizations/falcon"
node_name               "$CHEF_NODE_NAME"
environment             "$CHEF_ENV"
log_level               :info
ssl_ca_path             "/etc/ssl/certs"
log_location            "/var/log/chef_client.log"
validation_client_name  "$CHEF_VALIDATOR"
ssl_verify_mode         :verify_none
fips                    false
EOP

cat <<EOP >/etc/pssidecar.json
{
  "env": "$PS_ENV",
  "cluster": "$PS_CLUSTER",
  "location": "aws.$REGION",
  "role": "${PS_ROLE}"
}
EOP

wget http://$CHEF_SERVER/chef/validation.pem -O /etc/chef/validation.pem
wget http://$CHEF_SERVER/chef/chef_latest.deb -O /var/cache/chef.deb
dpkg -i /var/cache/chef.deb

chef-client -j /etc/chef/first-boot.json -o 'role[bootstrap]'
chef-client -j /etc/chef/first-boot.json
chef-client -j /etc/chef/first-boot.json