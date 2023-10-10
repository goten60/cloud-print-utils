#!/bin/bash
# Don't forget to set these env variables in aws lambda
# GDK_PIXBUF_MODULE_FILE="/opt/lib/loaders.cache"
# XDG_DATA_DIRS="/opt/lib"
set -e
yum install -y yum-utils rpmdevtools
cd /tmp
yumdownloader --resolve libtool-ltdl.x86_64

rpmdev-extract -- *rpm

mkdir /opt/lib
cp -P -r /tmp/*/usr/lib64/* /opt/python/lib

yum -y install libxml2-devel xmlsec1-devel xmlsec1-openssl-devel libtool-ltdl-devel gcc

mkdir -p "/opt/python/lib/python3.11/site-packages"
mkdir -p "/opt/lib"
python3 -m pip install xmlsec -t "/opt/python/lib/python3.11/site-packages"

cp `rpm -ql xmlsec1 | grep "libxmlsec1.so.1$"` "/opt/lib/"
cp `rpm -ql xmlsec1 | grep "libxmlsec1.so.1$"` "/opt/python/lib/"
cp `rpm -ql xmlsec1-openssl | grep "libxmlsec1-openssl.so$"` "/opt/lib/"
cp `rpm -ql xmlsec1-openssl | grep "libxmlsec1-openssl.so$"` "/opt/python/lib/"
cp `rpm -ql xmlsec1-openssl | grep "libltdl.so$"` "/opt/lib/"
cp `rpm -ql libtool | grep "libltdl.so$"` "/opt/python/lib/"

cd /opt
zip -r9 /out/layer.zip lib/* python/*
