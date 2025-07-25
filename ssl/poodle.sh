#!/usr/bin/env bash

openssl s_client -connect $2:$1 -ssl3
