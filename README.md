I had trouble getting boot2docker 1.7 start on Yosemite b/c of weird TLS stuff.  Here's what fixed it for me:

```
boot2docker start
boot2docker shellinit
boot2docker ssh sudo /etc/init.d/docker restart
```

## To build it

```
docker build -t mapr-drill .
```

## To start it

```
docker run -it \
  -p 80:80 \
  -p 8888:8888 \
  -p 8047:8047 \
  -v $(pwd):/usr/home \
  -w /usr/home \
  oreillymedia/mapr-drill \
  /bin/bash
```



docker run -it \
  -d \
  -p 8888:8888 \
  -p 8047:8047 \
  -w /usr/home \
  oreillymedia/mapr-drill \
  /usr/home/start.sh


Then, once you're at the shell, run start script

```
./start.sh
```

## tmpnb setup

To run under tmpnb:

```
export TOKEN=$( head -c 30 /dev/urandom | xxd -p )

docker run \
   --net=host \
   -d \
   -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
   jupyter/configurable-http-proxy \
  --default-target http://127.0.0.1:9999

docker run \
   --net=host \
   -d \
   -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
   -v /var/run/docker.sock:/docker.sock \
   zischwartz/tmpnb python orchestrate.py \
   --image="oreillymedia/mapr-drill" \
   --allow_origin="*" \
   --command="/usr/home/start.sh" \
   --cull_timeout=240 \
   --cull_period=60 \
   --pool_size=3
```
