#!/bin/bash

# Install the build-ova script, overwriting it if it already exists
rm -f $HOME/bin/build-ova
install -m 755 ./build-ova.sh $HOME/bin/build-ova
