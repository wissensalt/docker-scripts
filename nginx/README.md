# Nginx basic

## Build
```sh
podman build -t nginx .
```


## Run
```sh
podman run -d --name wissensalt-nginx -p 80:80 -p 443:443 nginx
```



