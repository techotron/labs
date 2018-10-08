# Nginx Docker Cheatsheet

## Nginx Docker Website Test
#####Build simple test website 
```buildoutcfg
docker build -t techotron/test-site-nginx .
```

#####Run 2 nginx website containers (using above image)
```buildoutcfg
docker run -d -p 8081:80 techotron/test-site-nginx && docker run -d -p 8082:80 techotron/test-site-nginx
```

#####Kill and delete all running containers
```buildoutcfg
docker kill $(docker ps -q) && docker rm $(docker ps -a -q)
```

#####Delete ALL images (this will delete every image on the docker host!)
```buildoutcfg
docker rmi $(docker images -q)
```

## Nginx Docker Load Balancer Test
#####Build simple load balancer container
`cd` to directory where the Dockerfile exists
```buildoutcfg
docker build -t techotron/test-lb-nginx .
```

#####Check bridge network gateway IP is used in upstream block
List networks running
```buildoutcfg
docker network ls
```
Chechk what network the container is connected to (most likely the bridge if default)
```buildoutcfg
docker inspect <containerId>
```
Check what the bridge network IP is
```buildoutcfg
docker network inspect bridge
```
Then edit the upstream block in the lb's nginx.conf
```buildoutcfg
  upstream localhost {
    server 172.17.0.1:8081 weight=5;
    server 172.17.0.1:8082 weight=5;
  }
```