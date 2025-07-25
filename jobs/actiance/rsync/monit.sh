SUPPORT="support1	\
	support2"

MYSQL="mysql1		\
	mysql2"

for i in $SUPPORT; do rsync --progress --stats ~/Dropbox/Configs/monit/monit-support.conf $i:/etc/monit.conf && ssh $i "/etc/init.d/monit reload" ; done
for i in $MYSQL; do rsync --progress --stats ~/Dropbox/Configs/monit/monit-mysql.conf $i:/etc/monit.conf && ssh $i "/etc/init.d/monit reload" ; done
