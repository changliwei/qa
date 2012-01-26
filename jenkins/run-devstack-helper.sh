#!/bin/bash

set -eux

thisdir=$(dirname $(readlink -f "$0"))

. "$thisdir/common.sh"

server=brontitall.eng.hq.xensource.com
stackdir="/tmp/stack"

cd $stackdir

cd devstack
git checkout xenservermodif

cd $stackdir/devstack
if [ ! -f localrc ]
then
    wget http://gold.eng.hq.xensource.com/localrc
fi

cd tools/xen
./build_xva.sh
