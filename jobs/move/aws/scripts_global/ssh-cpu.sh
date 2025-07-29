#!/usr/bin/env bash

export cve="CVE-2017-5715|CVE-2017-5753|CVE-2017-5754"
cd ~/bin/aws/scripts_global && rm -rf instances.txt output.txt

echo && echo "Authenticating to Vault. "
if ! vault login -method=github key="$VAULT_AUTH_GITHUB_TOKEN"; then
  echo && echo "Vault Auth Failed! Please correct." && exit 1
fi

aws ec2 describe-instances --instance-ids --query "Reservations[].Instances[].[InstanceId, KeyName, PrivateDnsName, Platform || 'Linux']" --filters 'Name=instance-state-name,Values=running' --output text |grep -v windows > instances.txt

mapfile -t XYZ < instances.txt

#total="${#XYZ[@]}"
total=5

for i in $( seq $total ); do
  read -r -a instance_data <<< "${XYZ[$i]}"
  instanceid="${instance_data[0]}"
  keyname="${instance_data[1]}"
  dns="${instance_data[2]}"
  export instanceid
  export keyname
  export dns
  amiid=$(aws ec2 describe-instances --instance-ids "$instanceid" --query Reservations[].Instances[].ImageId --output text)
  export amiid
  aminame=$(aws ec2 describe-images --image-ids "$amiid" --query Images[].Name --output text)
  export aminame

  if [[ $aminame = "amzn-hvm-ecs"* ]]; then
    export user="ec2-user"
  else
    export user="centos"
  fi

  if [[ "$keyname" != *".pem" ]]; then
    export keyname=${keyname}.pem
  fi

  echo && echo "Server $i out of $total"

  if [[ ! -f ~/.keys/$keyname ]]; then
    if vault list /secret/awskeys/ |grep "$keyname"; then
      vault read -field=value /secret/awskeys/"$keyname" > ~/.keys/"$keyname"
      chmod 600 ~/.keys/"$keyname"
    else
      echo && echo "$instanceid@$keyname $user@$dns: Key not found"
    fi
  fi

  if [[ -z $keyname ]]; then
    echo && echo "No Suitable Key Has been found!"
  else
    echo && echo "$instanceid"@"$keyname" "$user"@"$dns": | tee -a output.txt
    ssh -i ~/.keys/"$keyname" "$user"@"$dns" "rpm -q --changelog kernel | egrep '$cve'" 2>&1 | tee -a output.txt
    if [[ $? == "1" ]]; then # This check is fine as it's checking the exit code of the previous command directly.
      echo "Vulnerable! "
    fi
  fi
done

denied=$(grep -c "Permission denied" < output.txt)
export denied
refused=$(grep -c "Connection refused" < output.txt)
export refused
timeout=$(grep -c "Operation timed out" < output.txt)
export timeout
closed=$(grep -c "Connection closed by remote host" < output.txt)
export closed
vulnerable=$(grep -ic "vulnerable" < output.txt)
export vulnerable

echo && echo "Vulnerable: $vulnerable"
echo && echo "Denied: $denied"
echo && echo "Timeout: $timeout"
echo && echo "Closed: $closed"
echo && echo "Refused: $refused"
