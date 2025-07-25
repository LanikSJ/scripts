#!/bin/sh

echo "Generating SSH keys and uploading to amgsjlrec01"
ssh-keygen -t dsa ; cat ~/.ssh/id_dsa.pub | ssh root@amgsjlrec01 "cat - >> ~/.ssh/authorized_keys"
echo "Rsync'ing singatures from amgsjlrec01"
rsync -avz amgsjlrec01:/opt/recog_env/ --exclude logs /opt/recog_env/
rsync -avz amgsjlrec01:/home/fingerprint/signatures* /home/fingerprint/ 
echo "All done"
