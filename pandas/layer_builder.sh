#!/bin/bash
# Don't forget to set these env variables in aws lambda
# GDK_PIXBUF_MODULE_FILE="/opt/lib/loaders.cache"
# XDG_DATA_DIRS="/opt/lib"
set -e

mkdir -p "/opt/python/lib/python3.11/site-packages"
python -m pip install "pandas==1.3.5" -t "/opt/python/lib/python3.11/site-packages"
python -m pip install "psycopg2-binary" -t "/opt/python/lib/python3.11/site-packages"

cd /opt
zip -r9 /out/layer.zip lib/* python/*
