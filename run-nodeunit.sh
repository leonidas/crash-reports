#!/bin/sh
mkdir -p test-js
rm -f test-js/*
./node_modules/coffee-script/bin/coffee --compile --output test-js test
NODE_ENV=test ./node_modules/nodeunit/bin/nodeunit test-js/* $1 $2 $3 $4 $5
