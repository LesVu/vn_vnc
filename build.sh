#!/bin/bash

docker build . -f Dockerfiles/cage.dockerfile --tag lesvu/vn_vnc:cage
docker build . -f Dockerfiles/Dockerfile --target boxed --tag lesvu/vn_vnc:boxed
docker build . -f Dockerfiles/Dockerfile --target fex --tag lesvu/vn_vnc:fex
if [ -n "$PUSH" ]; then
	docker push lesvu/vn_vnc:fex
	docker push lesvu/vn_vnc:boxed
	docker push lesvu/vn_vnc:cage
fi
