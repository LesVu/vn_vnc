#!/bin/bash

docker build . -f Dockerfile --no-cache --tag lesvu/vn_vnc:latest
docker push lesvu/vn_vnc:latest
