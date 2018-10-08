# Nginx Docker Cheatsheet

## Nginx Docker Test
Build simple test website 
```buildoutcfg
docker build -t techotron/test-site-nginx .
```

Run 2 nginx website containers (using above image)
```buildoutcfg
docker run -d -p 8081:80 techotron/test-site-nginx && docker run -d -p 8082:80 techotron/test-site-nginx
```

Kill and delete all running containers
```buildoutcfg
docker kill $(docker ps -q) && docker rm $(docker ps -a -q)
```

Delete ALL images (this will delete every image on the docker host!)
```buildoutcfg
docker rmi $(docker images -q)
```