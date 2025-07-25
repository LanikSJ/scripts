echo "Syncing Certs"
rsync -avpr --delete ~/Configs/ldap/nss/certs/ ~/Drive/Cloud\ Services/Cloud\ Systems/LDAP/certs/
echo "Syncing RHEL5"
rsync -avpr --delete ~/Configs/ldap/nss/redhat5/ ~/Drive/Cloud\ Services/Cloud\ Systems/LDAP/redhat5/
echo "Syncing RHEL6"
rsync -avpr --delete ~/Configs/ldap/nss/redhat6/ ~/Drive/Cloud\ Services/Cloud\ Systems/LDAP/redhat6/
echo "Syncing Ubuntu12"
rsync -avpr --delete ~/Configs/ldap/nss/ubuntu12/ ~/Drive/Cloud\ Services/Cloud\ Systems/LDAP/ubuntu12/
echo "Syncing Ubuntu14"
rsync -avpr --delete ~/Configs/ldap/nss/ubuntu14/ ~/Drive/Cloud\ Services/Cloud\ Systems/LDAP/ubuntu14/
