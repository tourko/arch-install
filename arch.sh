#!/bin/bash

# 1. Boot from Live CD
# 2. systemctl start sshd
# 3. Set password

HOST=$1

tar -cjf config.tar.bz2 config
scp config.tar.bz2 root@$HOST:/tmp
rm config.tar.bz2

ssh -T root@$HOST 'sh' < install.sh
