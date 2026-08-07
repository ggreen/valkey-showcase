

```shell
podman  network  create valkey
```
mkdir $PWD/runtime


Start Servers



```shell
echo "Starting Site 1"

podman run -d   --rm --network=valkey -p 7001:7001 -v $PWD/runtime:/usr/local/etc/valkey-runtime -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey --hostname valkey-site1-server-1 --name valkey-site1-server-1 valkey/valkey:9.1 valkey-server  /usr/local/etc/valkey/valkey-site1-server-1.conf --port 7001
podman run -d --rm --network=valkey -p 7002:7002 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey --hostname valkey-site1-server-2  --name valkey-site1-server-2 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site1-server-2.conf  --port 7002


echo "Starting Site 2"

podman run -d --rm --network=valkey -p 7004:7004 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey  --hostname valkey-site2-server-1  --name valkey-site2-server-1 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site2-server-1.conf  --port 7004
podman run -d --rm --network=valkey -p 6705:6705 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey  --hostname valkey-site2-server-2  --name valkey-site2-server-2 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site2-server-2.conf  --port 7005

echo "Starting Site 3"

podman run -d --rm --network=valkey -p 7003:7003 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey  --hostname valkey-site3-server-1  --name valkey-site3-server-1 valkey/valkey:9.1 valkey-server  /usr/local/etc/valkey/valkey-site3-server-1.conf  --port 7003
podman run -d --rm --network=valkey -p 7006:7006 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey  --hostname valkey-site3-server-2  --name valkey-site3-server-2 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site3-server-2.conf  --port 7006
```


Create cluster

```shell
podman exec -it valkey-site1-server-1 valkey-cli --cluster create valkey-site1-server-1:7001 valkey-site2-server-1:7004  valkey-site3-server-1:7003  valkey-site1-server-2:7002 valkey-site2-server-2:7005 valkey-site3-server-2:7006  --cluster-replicas 1
```

Interact with the cluster


```shell
podman exec -it valkey-site3-server-2 valkey-cli -c -p 7006 -h 127.0.0.1
```

```shell
set customer.1 '{"id" : "1001"}'
set customer.2 '{"id" : "1002"}'
set customer.3 '{"id" : "1003"}'
set customer.4 '{"id" : "1004"}'
set customer.5 '{"id" : "1005"}'
set customer.6 '{"id" : "1006"}'
set customer.7 '{"id" : "1007"}'
set customer.8 '{"id" : "1008"}'
```


```shell
INFO replication
```

```shell
CLUSTER NODES
```

```shell
get customer.1
get customer.2
get customer.3
get customer.4
get customer.5
get customer.6
get customer.7
get customer.8
```



View Cluster Details 

```shell
CLUSTER INFO
```




Crash site 1

```shell
podman rm  -f valkey-site1-server-1 valkey-site1-server-2
```

```shell
get customer.1
get customer.2
get customer.3
get customer.4
get customer.5
get customer.6
get customer.7
get customer.8
```

Review Cluster Nodes



```shell
podman exec -it valkey-site2-server-1 valkey-cli -p 7004 -h valkey-site2-server-1 cluster nodes
```



```shell
podman exec -it valkey-site2-server-1 valkey-cli -p 7004
```

```shell
get customer.1
get customer.2
get customer.3
get customer.4
get customer.5
get customer.6
get customer.7
get customer.8
```

Start Server 1

```shell
podman run -d --rm --network=valkey  -v $PWD/runtime:/usr/local/etc/valkey-runtime -v $PWD/deployments/local/valkey/config/multi-site/3-sites:/usr/local/etc/valkey --hostname valkey-site1-server-1 --name valkey-site1-server-1 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site1-server-1.conf
```
View server 1 logs

```shell
podman logs -f valkey-site1-server-1
```



Review Cluster Nodes

```shell
podman exec -it valkey-site2-server-1 valkey-cli -p 7004 -h valkey-site2-server-1 cluster nodes
```


Kill Server 2

```shell
podman rm  -f valkey-site1-server-2
```

```shell
podman exec -it valkey-site2-server-1 valkey-cli -p 7004
```

```shell
get customer.1
get customer.2
get customer.3
get customer.4
get customer.5
get customer.6
```


Kill Server 6

```shell
podman rm  -f valkey-site3-server-2
```

```shell
podman exec -it valkey-site3-server-1 valkey-cli -p 7003
```

```shell
get customer.1
get customer.2
get customer.3
get customer.4
get customer.5
get customer.6
```

View missing slots

```shell
podman exec -it valkey-site3-server-1 valkey-cli --cluster check valkey-site3-server-1:7003
podman exec -it valkey-site2-server-1 valkey-cli --cluster check valkey-site2-server-1:7004
podman exec -it valkey-site2-server-2 valkey-cli --cluster check valkey-site2-server-2:7005
```


```shell
podman exec -it valkey-site2-server-1 valkey-cli --cluster fix valkey-site2-server-1:7004  --cluster-fix-with-unreachable-primaries
```


-------------------

# Cleanup 
```shell
podman rm -f valkey-site1-server-1 valkey-site1-server-2 valkey-site3-server-1 valkey-site2-server-1 valkey-site2-server-2 valkey-site3-server-2 

rm runtime/*.conf
```