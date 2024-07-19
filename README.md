# Thing need to run

1. volume `/Games`
2. port `5900`
3. Init

Run

```bash
docker run -it -d --name name --privileged -v path:/Games \
-p 4713:4713 -p 5700:5700 -p 5900:5900 -p 6080:6080 --init \
--dns 1.1.1.1 --dns 1.0.0.1 --shm-size=256mb --device device \
--cap-add=SYS_ADMIN lesvu/vn_vnc:latest
```
