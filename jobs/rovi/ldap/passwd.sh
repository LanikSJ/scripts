getent passwd |awk -F\: '{print $3}' |sort |more
