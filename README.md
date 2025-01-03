# Thing need to run

## Run

```bash
docker run -it -d --name vnvnc --privileged -v ~/Games:/Games \
-p 4713:4713 -p 5700:5700 -p 5900:5900 -p 6100:6100 --init \
--dns 1.1.1.1 --dns 1.0.0.1 --shm-size=256mb lesvu/vn_vnc:latest
```
