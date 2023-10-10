#!/bin/bash
# Don't forget to set these env variables in aws lambda
# GDK_PIXBUF_MODULE_FILE="/opt/lib/loaders.cache"
# XDG_DATA_DIRS="/opt/lib"
set -e
yum -y install libxml2-devel xmlsec1-devel xmlsec1-openssl-devel libtool-ltdl-devel gcc

mkdir -p "/opt/python/lib/python3.11/site-packages"
python3 -m pip install xmlsec -t "/opt/python/lib/python3.11/site-packages"

cd /opt
zip -r9 /out/layer.zip lib/* python/*
