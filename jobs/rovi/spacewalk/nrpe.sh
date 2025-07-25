if [ `rpm -qa | grep nrpe > /dev/null 2>&1; echo $?` -eq 0 ]; then
rhncfg-client get /etc/nagios/nrpe.cfg /usr/lib/nagios/plugins/check_mem_proc.sh
chmod +x /usr/lib/nagios/plugins/check_mem_proc.sh && chown -R nagios.nagios /usr/lib/nagios
service nrpe restart && exit 0
else
echo "Nagios not installed!" && exit 1
fi