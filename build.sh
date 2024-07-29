#!/bin/bash

docker build . -f Dockerfile.boxed --no-cache --build-arg="user=abc" --tag lesvu/vn_vnc:latest
docker push lesvu/vn_vnc:boxed
docker build . -f Dockerfile.fex --no-cache --build-arg="user=abc" --tag lesvu/vn_vnc:latest
docker push lesvu/vn_vnc:fex
