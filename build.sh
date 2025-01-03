#!/bin/bash

docker build . --target base --tag lesvu/vn_vnc:base
docker build . --target boxed --tag lesvu/vn_vnc:boxed
docker build . --target fex --tag lesvu/vn_vnc:fex
if [ -n "$PUSH" ]; then
	docker push lesvu/vn_vnc:fex
	docker push lesvu/vn_vnc:boxed
	docker push lesvu/vn_vnc:base
fi
