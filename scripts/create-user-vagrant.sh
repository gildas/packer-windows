#!/bin/bash -euxo pipefail

HOME_DIR="${HOME_DIR:-/home/vagrant}"

install -v -o vagrant -g vagrant -m 0700 -d $HOME_DIR/.ssh
curl --insecure -o $HOME_DIR/.ssh/authorized_keys -kL 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub'
chown vagrant:vagrant $HOME_DIR/.ssh/authorized_keys
chmod 600 $HOME_DIR/.ssh/authorized_keys

cat <<'EOF' > $HOME_DIR/.bash_profile
[ -f ~/.bashrc ] && . ~/.bashrc
export PATH=$PATH:/sbin:/usr/sbin:$HOME/bin
EOF
