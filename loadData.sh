#!/bin/bash

# clean up database
for i in {1..1000}
do
  redis-cli set $i $i > /dev/null
done

echo "Data loaded"
