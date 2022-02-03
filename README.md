# misc_docker

## Build

```
./build.sh
```

## Run

```
docker run --name novnc --publish 6080:80 novnc
```

```
docker exec -it novnc bash
```

Acces to http://localhost:6080

http://localhost/vnc_with_browser_joy.html?autoconnect=1&resize=remote&wsport=9090&wsaddress=localhost
