SERVERS="support1	\
	support2	\
	mysql1		\
	mysql2		\
	actweb		\
	actweb-bak"

for i in $SERVERS; do echo && echo "Updating $i on `date`" && ssh $i "yum -y update" && echo "Done on `date`"; done
