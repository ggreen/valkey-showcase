

```shell
podman  network  create valkey
```
mkdir $PWD/runtime


Start Servers

```shell
podman run -d --rm --network=valkey  -v $PWD/runtime:/usr/local/etc/valkey-runtime -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey --hostname valkey-server1 --name valkey-server1 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-1.conf
podman run -d --rm --network=valkey  -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey --hostname valkey-server2  --name valkey-server2 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-2.conf
podman run -d --rm --network=valkey -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey  --hostname valkey-server3  --name valkey-server3 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-3.conf
podman run -d --rm --network=valkey -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey  --hostname valkey-server4  --name valkey-server4 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-4.conf
podman run -d --rm --network=valkey -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey  --hostname valkey-server4  --name valkey-server5 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-5.conf
podman run -d --rm --network=valkey -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v /Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/deployments/local/valkey/config:/usr/local/etc/valkey  --hostname valkey-server4  --name valkey-server6 valkey/valkey:8.1 valkey-server /usr/local/etc/valkey/valkey-server-6.conf

```


Create cluster

```shell
podman exec -it valkey-server1 valkey-cli --cluster create valkey-server1:7000 valkey-server2:7000  valkey-server3:7000 valkey-server4:7000 valkey-server5:7000 valkey-server6:7000  --cluster-replicas 1
```

Interact with the cluster


```shell
podman exec -it valkey-server2 valkey-cli -c -p 7000 -h 127.0.0.1
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
podman exec -it valkey-server1 valkey-cli -p 7000 cluster nodes | grep master
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
podman exec -it valkey-server4 valkey-cli -p 7000 -h valkey-server4 cluster nodes
```


```shell
get customer.cluster:1
get customer.cluster:2
```

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
podman exec -it valkey-server4 valkey-cli -p 7000 -h valkey-server4 cluster nodes
```

-------------------

# Cleanup 
```shell
podman rm -f valkey-server1 valkey-server2 valkey-server3 valkey-server4 valkey-server5 valkey-server6

```