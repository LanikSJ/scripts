#!/bin/bash
 
CHEF_ROLE="cicd-k8-artifactory-proxy"
 
# For guidance on the following, see: https://wiki.cs.sys/x/cvEhBQ
CALLSIGN="eagle"
CHEF_ENVIRONMENT="csgov"
 
#ENV_ROLE="$CHEF_ROLE-$CALLSIGN" # Optional to add an environment role
#RUNLIST_APPEND=""               # Optional to add to your Chef runlist
 
POOL="util"        # E.g.: util, red, black, gyr, lanner
NETWORK_TYPE="main"     # Use "dmz" for DMZ instances
SWIMLANE="p"            # Swimlane or "p" for pool level
 
# For guidance on sidecar clusters, see: https://wiki.cs.sys/x/eu2ZD
SIDECAR_ROLE="$CHEF_ROLE"
SIDECAR_CLUSTER="$POOL-$SWIMLANE"
SIDECAR_ASSUME_AWS="true"   # May have to be set to false in the DC
#SIDECAR_REGION=csdc.rno1 # Automatic in AWS. DC may need to specify region
 
PACKAGE_TYPE="deb"        # Use rpm for RHEL
 
USE_PROXY=true            # Set to true for restricted egress networks
# PROXY_URL=""            # Optional to override the cloud's default proxy URL
 
BOOTSTRAP_ROLE="bootstrap" # For non-standard bootstrap
 
 
#########################################################################################
#                                    *** WARNING ***                                    #
#                          Do NOT touch any of the code below!                          #
# If there's a use-case we do not currently support, please reach out to #ask-infra-eng #
#########################################################################################
 
#######################
# Generated variables #
#######################
 
INSTANCE_ID=$(cloud-init query instance_id)
 
# Lets start with sane defaults
CHEF_SERVER="chef.$CALLSIGN.eyrie.cloud"
CHEF_ORGANIZATION="$CALLSIGN"
STAGE="$CALLSIGN"
PS_BUCKET="cs-$CALLSIGN-util-main-p-parameterservice"
FF_BUCKET="cs-$CALLSIGN-util-main-p-feature-flags"
SIDECAR_ENVIRONMENT="$CALLSIGN"
PROXY_ZONE="$CALLSIGN"
AWS_REGION="aws.$(cloud-init query availability_zone | sed 's/[a-z]$//')"
SIDECAR_REGION="${SIDECAR_REGION:-$AWS_REGION}"
 
# And add overrides as necessary
case $CALLSIGN in
  mav | viper | lion | dodo | merlin)
    ;;
  eagle)
    CHEF_ORGANIZATION="falcon"
    STAGE="csgov"
    SIDECAR_ENVIRONMENT="csgov"
    PS_BUCKET="cs-gov-infraapi-parameterservice"
    FF_BUCKET="cs-gov-feature-flags"
    ;;
  beta | blue)
    CHEF_SERVER="chef.csa.eyrie.cloud"
    CHEF_ORGANIZATION="crowdstrike"
    PROXY_ZONE="beta"
    SIDECAR_ENVIRONMENT="prod"
    PS_BUCKET="cs-prod-infraapi-parameter"
    FF_BUCKET="cs-prod-feature-flags"
    ;;
  devtest)
    CHEF_SERVER="chef.devtest.eyrie.cloud"
    CHEF_ORGANIZATION="crowdstrike"
    STAGE="$CHEF_ENVIRONMENT"
    PS_BUCKET="cs-dev-infraapi-parameter"
    FF_BUCKET="cs-dev-feature-flags"
    ;;
  *)
    echo "Invalid cloud callsign: $CALLSIGN"
    exit 1
    ;;
esac
 
[ $USE_PROXY = true ] && PROXY_URL="${PROXY_URL:-http://infra-proxy.$PROXY_ZONE.eyrie.cloud:3128}" || PROXY_URL=""
 
RUNLIST="\"role[$CHEF_ROLE]\""
[[ $ENV_ROLE ]] && RUNLIST+=", \"role[$ENV_ROLE]\""
[[ $RUNLIST_APPEND ]] && RUNLIST+=", $RUNLIST_APPEND"
 
PACKAGE_TYPE="${PACKAGE_TYPE:-deb}"
case $PACKAGE_TYPE in
  "rpm") PACKAGE_MANAGER="rpm" ;;
  "deb") PACKAGE_MANAGER="dpkg" ;;
  *)
    echo "Invalid package type: $PACKAGE_TYPE"
    exit 1
    ;;
esac
 
########################
# System configuration #
########################
 
# Generate hostname if not running in AWS
# Schema: <chef-role>-csdc-<random-string>
# The hostname is being truncated to the maximum allowed number of 63 chars.
if [[ "$SIDECAR_REGION" =~ ^csdc.*$ ]]; then
  HOSTNAME=$(printf '%.63s' "${CHEF_ROLE}-csdc-$(openssl rand -hex 9)")
  echo "${HOSTNAME}" > /etc/hostname
  hostname --file /etc/hostname
fi
 
mkdir /etc/chef/
 
PROXY_ATTRIBUTE=""
[ -n "$PROXY_URL" ] && read -d '' -r PROXY_ATTRIBUTE <<- NOVALIDATE
  ,
  "infra_proxy": { "url": "$PROXY_URL" }
NOVALIDATE
 
cat <<NOVALIDATE >/etc/chef/first-boot.json
{
  "run_list":[$RUNLIST],
  "csbase": {
     "enable_fips": false
  },
  "ubuntu_pro": {
     "register": false
  },
  "csdns":{
     "stage":"$STAGE",
     "callsign": "$CALLSIGN",
     "pool": "$POOL",
     "swimlane": "$SWIMLANE",
     "network": "$NETWORK_TYPE"
  }${PROXY_ATTRIBUTE}
}
NOVALIDATE
 
cat <<EOP >/etc/chef/client.rb
chef_server_url         "https://$CHEF_SERVER/organizations/$CHEF_ORGANIZATION"
node_name               "$CALLSIGN-$POOL-$NETWORK_TYPE-$SWIMLANE-$CHEF_ROLE-$INSTANCE_ID"
environment             "$CHEF_ENVIRONMENT"
log_level               :info
ssl_ca_path             "/etc/ssl/certs"
log_location            "/var/log/chef_client.log"
validation_client_name  "$CHEF_ORGANIZATION-validator"
ssl_verify_mode         :verify_none
fips                    false
 
INFRA_PROXY="$PROXY_URL"
unless INFRA_PROXY.empty?
  http_proxy              "#{INFRA_PROXY}"
  https_proxy             "#{INFRA_PROXY}"
  no_proxy                "169.254.169.254,127.0.0.1,localhost,amazonaws.com,eyrie.cloud"
end
EOP
 
cat <<NOVALIDATE >/etc/pssidecar.json
{
  "assume_aws": $SIDECAR_ASSUME_AWS,
  "env": "$SIDECAR_ENVIRONMENT",
  "location": "$SIDECAR_REGION",
  "cluster": "$SIDECAR_CLUSTER",
  "role": "$SIDECAR_ROLE",
  "parameter_bucket": "$PS_BUCKET",
  "feature_flag_bucket": "$FF_BUCKET"
}
NOVALIDATE
 
wget "http://$CHEF_SERVER/chef/validation.pem" -O /etc/chef/validation.pem
 
wget "http://$CHEF_SERVER/chef/chef_latest.$PACKAGE_TYPE" -O "/var/cache/chef.$PACKAGE_TYPE"
$PACKAGE_MANAGER -i "/var/cache/chef.$PACKAGE_TYPE"
 
chef-client -j /etc/chef/first-boot.json -o "role[$BOOTSTRAP_ROLE]"
chef-client -j /etc/chef/first-boot.json