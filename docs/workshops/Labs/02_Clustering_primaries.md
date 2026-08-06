

```shell
podman  network  create valkey
```
mkdir $PWD/runtime


Start Servers

```shell
podman run -d --rm --network=valkey -p 6701:6701 -v $PWD/runtime:/usr/local/etc/valkey-runtime -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey --hostname valkey-server1 --name valkey-server1 valkey/valkey:8.1 valkey-server  /usr/local/etc/valkey/valkey-server-1.conf --port 7001
podman run -d --rm --network=valkey -p 6702:6702 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey --hostname valkey-server2  --name valkey-server2 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-2.conf  --port 7002
podman run -d --rm --network=valkey -p 6703:6703 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey  --hostname valkey-server3  --name valkey-server3 valkey/valkey:8.1 valkey-server  /usr/local/etc/valkey/valkey-server-3.conf  --port 7003
```


Create cluster

```shell
podman exec -it valkey-server1 valkey-cli --cluster create valkey-server1:7001 valkey-server2:7002  valkey-server3:7003 --cluster-replicas 0
```

Interact with the cluster


```shell
podman exec -it valkey-server2 valkey-cli -c -p 7002 -h 127.0.0.1
```

```shell
set customer.cluster:1 '{"id" : "1001"}'
set customer.cluster:2 '{"id" : "1002"}'
set customer.cluster:3 '{"id" : "1003"}'
set customer.cluster:4 '{"id" : "1004"}'
set customer.cluster:5 '{"id" : "1005"}'
set customer.cluster:6 '{"id" : "1006"}'
```


```shell
get customer.cluster:1
get customer.cluster:2
get customer.cluster:3
get customer.cluster:4
get customer.cluster:5
get customer.cluster:6
```



View Cluster DEtails 

```shell
CLUSTER INFO
```


identify a primary and crash it with the following command:

```shell
podman exec -it valkey-server1 valkey-cli -p 7001 cluster nodes
```


```shell
podman inspect -f '{{.NetworkSettings.Networks.valkey.IPAddress}}' valkey-server1
podman inspect -f '{{.NetworkSettings.Networks.valkey.IPAddress}}' valkey-server2
podman inspect -f '{{.NetworkSettings.Networks.valkey.IPAddress}}' valkey-server3
```


Review Logs

```shell
podman logs -f valkey-server2
```

```shell
podman logs -f valkey-server6
```


Crash

```shell
podman rm  -f valkey-server1
```

Review Cluster Nodes

```shell
podman exec -it valkey-server2 valkey-cli -p 7002 -h valkey-server2 cluster nodes
```

View missing slots

```shell
podman exec -it valkey-server2 valkey-cli --cluster check valkey-server2:7002
podman exec -it valkey-server3 valkey-cli --cluster check valkey-server3:7003
```

```shell
podman exec -it valkey-server2 valkey-cli -p 7002
```

```shell
get customer.cluster:1
get customer.cluster:2
get customer.cluster:3
get customer.cluster:4
get customer.cluster:5
get customer.cluster:6
```

Expected: 127.0.0.1:7002> get customer.cluster:1
(error) CLUSTERDOWN The cluster is down

Fix Missing Slots

```shell
podman exec -it valkey-server2 valkey-cli --cluster fix valkey-server2:7002  --cluster-fix-with-unreachable-primaries 
```

```shell
podman exec -it valkey-server2 valkey-cli -p 7002
```

```shell
get customer.cluster:1
get customer.cluster:2
get customer.cluster:3
get customer.cluster:4
get customer.cluster:5
get customer.cluster:6
```

Some entries have moved and some are nill (lost data)

Start Server 1

```shell
podman run -d --rm --network=valkey  -v $PWD/runtime:/usr/local/etc/valkey-runtime -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey --hostname valkey-server1 --name valkey-server1 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-1.conf
```
View server 1 logs

```shell
podman logs -f valkey-server1
```



Review Cluster Nodes

```shell
podman exec -it valkey-server4 valkey-cli -p 7004 -h valkey-server4 cluster nodes
```


Kill Server 2

```shell
podman rm  -f valkey-server2
```

```shell
podman exec -it valkey-server4 valkey-cli -p 7004
```

```shell
get customer.cluster:1
get customer.cluster:2
```


-------------------

# Cleanup 
```shell
podman rm -f valkey-server1 valkey-server2 valkey-server3 valkey-server4 valkey-server5 valkey-server6

```