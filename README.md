# Thing need to run

1. volume `/Games`
2. port `5900`
3. Init

Systemd
`--cgroup-parent=docker.slice --tmpfs /run --tmpfs /tmp --tmpfs /run/lock`

```
--privileged -v path:/Games -p 5900:5900 --init --dns 1.1.1.1 --dns 1.0.0.1 --shm-size=256mb --device /dev/dri --cap-add=SYS_ADMIN
```
