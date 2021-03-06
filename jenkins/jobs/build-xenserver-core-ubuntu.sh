#!/bin/bash

set -eu

REMOTELIB=$(cd $(dirname $(readlink -f "$0")) && cd remote && pwd)
XSLIB=$(cd $(dirname $(readlink -f "$0")) && cd xslib && pwd)
TESTLIB=$(cd $(dirname $(readlink -f "$0")) && cd tests && pwd)

function print_usage_and_die
{
cat >&2 << EOF
usage: $0 XENSERVERNAME SLAVE_PARAM_FILE

Build xenserver-core packages

positional arguments:
 XENSERVERNAME     The name of the XenServer
 SLAVE_PARAM_FILE  The slave VM's parameters will be placed to this file
EOF
exit 1
}

XENSERVERNAME="${1-$(print_usage_and_die)}"
SLAVE_PARAM_FILE="${2-$(print_usage_and_die)}"

set -x

WORKER=$(cat $XSLIB/get-worker.sh | "$REMOTELIB/bash.sh" "root@$XENSERVERNAME" none raring raring)

echo "$WORKER" > $SLAVE_PARAM_FILE

"$REMOTELIB/bash.sh" $WORKER << END_OF_XSCORE_BUILD_SCRIPT
set -eux

sudo tee /etc/apt/apt.conf.d/90-assume-yes << APT_ASSUME_YES
APT::Get::Assume-Yes "true";
APT::Get::force-yes "true";
APT_ASSUME_YES

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install git ocaml-nox

git clone https://github.com/xapi-project/xenserver-core.git -b master xenserver-core

cd xenserver-core

sed -ie 's,http://gb.archive.ubuntu.com/ubuntu/,http://mirror.anl.gov/pub/ubuntu/,g' scripts/deb/pbuilderrc.in

cat >> pbuilderrc.in << EOF
export http_proxy=http://gold.eng.hq.xensource.com:8000
EOF

sudo ./configure.sh
./makemake.py > Makefile
sudo make
END_OF_XSCORE_BUILD_SCRIPT
