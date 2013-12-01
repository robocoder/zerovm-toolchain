#!/usr/bin/env bash
#
# ZeroVM gcc toolchain
#

set -e

# install pre-requisites
apt-get update
apt-get install -y libc6-dev-i386 \
                   libglib2.0-dev \
                   pkg-config \
                   git \
                   build-essential \
                   automake \
                   autoconf \
                   libtool \
                   g++-multilib \
                   texinfo \
                   flex \
                   bison \
                   groff \
                   curl \
                   libncurses5-dev \
                   libexpat1-dev \
                   subversion

# install zeromq >= 3.2.4
if [ ! -d /home/vagrant/zeromq-4.0.3 ]; then
    cd /home/vagrant

    curl http://download.zeromq.org/zeromq-4.0.3.tar.gz | gunzip | tar xvf -
fi
cd zeromq-4.0.3
chown -R root:root .
./configure
make
make install

ldconfig

cd /home/vagrant

# set up environment variables (and persist)
export HOME=/home/vagrant
export ZEROVM_ROOT=$HOME/zerovm
export ZVM_PREFIX=$HOME/zvm-root
export ZRT_ROOT=$HOME/zrt

if [ ! -d $ZVM_PREFIX/bin ]; then
    mkdir -p $ZVM_PREFIX/bin
fi

export PATH=$ZVM_PREFIX/bin:$PATH

if ! fgrep ZEROVM_ROOT $HOME/.bashrc; then
    cat >>$HOME/.bashrc <<EOF
export ZEROVM_ROOT=\$HOME/zerovm
export ZVM_PREFIX=\$HOME/zvm-root
export ZRT_ROOT=\$HOME/zrt
export PATH=\$ZVM_PREFIX/bin:\$PATH
EOF
fi

# clone things
if [ ! -d $ZEROVM_ROOT ]; then
    git clone https://github.com/zerovm/zerovm.git $ZEROVM_ROOT
fi
if [ ! -d $ZEROVM_ROOT/valz ]; then
    git clone https://github.com/zerovm/validator.git $ZEROVM_ROOT/valz
fi
if [ ! -d $ZRT_ROOT ]; then
    git clone https://github.com/zerovm/zrt.git $ZRT_ROOT
fi

# skip autotests because zerovm is not permitted to run as root
sed --in-place 's/all: notests autotests/all: notests/' $ZRT_ROOT/Makefile

if [ ! -d $HOME/zvm-toolchain ]; then
    git clone https://github.com/zerovm/toolchain.git $HOME/zvm-toolchain
fi

cd $HOME/zvm-toolchain/SRC
if [ ! -d $HOME/zvm-toolchain/SRC/linux-headers-for-nacl ]; then
    git clone https://github.com/zerovm/linux-headers-for-nacl.git
fi
if [ ! -d $HOME/zvm-toolchain/SRC/gcc ]; then
    git clone https://github.com/zerovm/gcc.git
fi
if [ ! -d $HOME/zvm-toolchain/SRC/glibc ]; then
    git clone https://github.com/zerovm/glibc.git
fi
if [ ! -d $HOME/zvm-toolchain/SRC/newlib ]; then
    git clone https://github.com/zerovm/newlib.git
fi
if [ ! -d $HOME/zvm-toolchain/SRC/binutils ]; then
    git clone https://github.com/zerovm/binutils.git
fi

# cleanup
cd $HOME/zvm-toolchain
make clean
cd $ZVM_PREFIX
rm -fr *

# build zerovm
cd $ZEROVM_ROOT/valz
make validator
make install
cd $ZEROVM_ROOT
make all
make install PREFIX=$ZVM_PREFIX

# build toolchain
cd $HOME/zvm-toolchain
make -j8

# install debugger
cd $HOME/zvm-toolchain/SRC
if [ ! -d $HOME/zvm-toolchain/SRC/gdb ]; then
    git clone https://github.com/zerovm/gdb.git
fi

mkdir -p gdb/BUILD
cd gdb/BUILD

../configure --program-prefix=x86_64-nacl- --prefix=$ZVM_PREFIX
make -j4
make install
