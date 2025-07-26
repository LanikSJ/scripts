#!/bin/zsh

fipson() {
    sed -i 's/fips=no/fips=yes/' "$(brew --prefix)/etc/openssl-fips@3/openssl.cnf"
}

fipsoff() {
    sed -i 's/fips=yes/fips=no/' "$(brew --prefix)/etc/openssl-fips@3/openssl.cnf"
}