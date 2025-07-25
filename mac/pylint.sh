#!/usr/bin/env bash

# No files argument will run on all dir tree
FILES=${1:-"*.py"}

# Should get path from inside the virtualenv
PYLINT_PATH=${2:-"pylint"}

# Disable common bugs with pylint 1.6.4
find . -type f -name "$FILES" | xargs "$PYLINT_PATH" --reports=n --disable=C0111,E0401,W0621,E1129,E0202 --rcfile=~/.pylintrc
