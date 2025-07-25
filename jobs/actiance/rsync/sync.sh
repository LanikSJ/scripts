#!/usr/bin/env bash

rsync -avhpre ssh --progress --stats support2:/usr/local/sbin/support* ~/bin/actiance/www/
rsync -avhpre ssh --progress --stats actweb-bak:/usr/local/sbin/actweb* ~/bin/actiance/www/
