#!/bin/sh

chown -R uploadr.uploadr /tmp/release
cp -rfpv /tmp/release/* /catalog/release
rm -rf /tmp/release
