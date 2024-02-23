#!/bin/bash

docker build . -f Dockerfile --no-cache --build-arg="user=abc" --tag lesvu/vn_vnc:latest
docker push lesvu/vn_vnc:latest
