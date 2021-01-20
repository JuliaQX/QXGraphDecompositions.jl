#!/usr/bin/env bash
docker run --rm -v `pwd`:/app qbit271/quickbb $@
# docker cp qbit271/quickbb:/app/tmp.out `pwd`/tmp.out
sleep 1s
