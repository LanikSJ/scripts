#!/usr/bin/env bash
# Random password generator

openssl rand -base64 12 |md5 |head -c12 && echo
