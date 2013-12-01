#!/usr/bin/env bash
#
# ZeroVM gcc toolchain
#

set -e

# install apt-get repository
'echo "deb [ arch=amd64 ] http://zvm.rackspace.com/v1/repo/ubuntu/ precise main" > /etc/apt/sources.list.d/zerovm-precise.list'
wget -O- https://zvm.rackspace.com/v1/repo/ubuntu/zerovm.pkg.key | apt-key add -
apt-get update
apt-get install -y zerovm \
                   zerovm-zmq \
                   zerovm-cli \
                   zerovm-dbg \
                   zerovm-dev \
                   gcc-4.4.3-zerovm \
                   make \
                   automake \
                   autoconf \
                   git \
                   gdb-zerovm
