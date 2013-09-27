#/bin/bash

set -eux

XENSERVERHOST=$1
XENSERVERPASSWORD=$2

TEMPKEYFILE=$(mktemp)

# Prepare slave requirements
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install xcp-xe stunnel sshpass

rm -f install-devstack-xen.sh || true
wget https://raw.github.com/citrix-openstack/qa/master/install-devstack-xen.sh
chmod 755 install-devstack-xen.sh
rm -f $TEMPKEYFILE
ssh-keygen -t rsa -N "" -f $TEMPKEYFILE
./install-devstack-xen.sh $TEMPKEYFILE $XENSERVERHOST $XENSERVERPASSWORD
