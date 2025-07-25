#!/bin/sh

for i in $( echo rhelupd1 ; echo rhelupd2 ) ; do
	scp ~/scripts/ldap-client.sh ~/scripts/change_home_dir.sh ~/scripts/revert_ldap.sh $i:
done
