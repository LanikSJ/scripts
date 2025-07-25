#!/usr/bin/env bash

rsync -avhpre ssh --progress --stats ~/bin/actiance/www/support-sync.sh support2:/usr/local/sbin/
rsync -avhpre ssh --progress --stats  ~/bin/actiance/www/actweb-sync.sh actweb-bak:/usr/local/sbin/
rsync -avhpre ssh --progress --stats  ~/bin/actiance/www/perms.sh support1:/usr/local/sbin/
ssh actweb-bak "chown root:root /usr/local/sbin/*.sh"
ssh support1 "chown root:root /usr/local/sbin/*.sh"
ssh support2 "chown root:root /usr/local/sbin/*.sh"
