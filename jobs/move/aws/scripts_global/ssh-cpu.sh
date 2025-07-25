#!/usr/bin/env bash

export cve="CVE-2017-5715|CVE-2017-5753|CVE-2017-5754"
cd ~/bin/aws/scripts_global && rm -rf instances.txt output.txt

echo && echo "Authenticating to Vault. "
vault login -method=github key=$VAULT_AUTH_GITHUB_TOKEN
if [[ $? != "0" ]]; then
  echo && echo "Vault Auth Failed! Please correct." && exit 1
fi

aws ec2 describe-instances --instance-ids --query 'Reservations[].Instances[].[InstanceId, KeyName, PrivateDnsName, Platform || `Linux`]' --filters 'Name=instance-state-name,Values=running' --output text |grep -v windows > instances.txt

IFS=$'\r\n' GLOBIGNORE='*' command eval  'XYZ=($(< instances.txt))'

#total="${#XYZ[@]}"
total=5

for i in $( seq $total ); do
  export instanceid=$(echo ${XYZ[$i]} |awk '{print $1}')
  export keyname=$(echo ${XYZ[$i]} |awk '{print $2}')
  export dns=$(echo ${XYZ[$i]} |awk '{print $3}')

  export amiid=$(aws ec2 describe-instances --instance-ids $instanceid --query Reservations[].Instances[].ImageId --output text)
  export aminame=$(aws ec2 describe-images --image-ids $amiid --query Images[].Name --output text)

  if [[ $aminame = "amzn-hvm-ecs"* ]]; then
    export user="ec2-user"
  else
    export user="centos"
  fi

  if [[ `echo $keyname` != *".pem" ]]; then
    export keyname=${keyname}.pem
  fi

  echo && echo "Server $i out of $total"

  if [[ ! -f ~/.keys/$keyname ]]; then
    vault list /secret/awskeys/ |grep $keyname
    if [[ $? == "0" ]]; then
      vault read -field=value /secret/awskeys/$keyname > ~/.keys/$keyname
      chmod 600 ~/.keys/$keyname
    else
      echo && echo "$instanceid@$keyname $user@$dns: Key not found"
    fi
  fi

  if [[ -z $keyname ]]; then
    echo && echo "No Suitable Key Has been found!"
  else
    echo && echo $instanceid@$keyname $user@$dns: | tee -a output.txt
    ssh -i ~/.keys/$keyname $user@$dns "rpm -q --changelog kernel | egrep '$cve'" 2>&1 | tee -a output.txt
    if [[ $? == "1" ]]; then
      echo "Vulnerable! "
    fi
  fi
done

export denied=$(cat output.txt |grep "Permission denied" |wc -l)
export refused=$(cat output.txt |grep "Connection refused" |wc -l)
export timeout=$(cat output.txt |grep "Operation timed out" |wc -l)
export closed=$(cat output.txt |grep "Connection closed by remote host" |wc -l)
export vulnerable=$(cat output.txt |grep -i "vulnerable" |wc -l)

echo && echo Vulnerable: $vulnerable
echo && echo Denied: $denied
echo && echo Timeout: $timeout
echo && echo Closed: $closed
echo && echo Refused: $refused
