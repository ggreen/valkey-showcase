

```shell
podman  network  create valkey
```
mkdir $PWD/runtime


Start Servers

```shell
echo "Starting Site 1"

podman run -d   --rm --network=valkey -p 7001:7001 -v $PWD/runtime:/usr/local/etc/valkey-runtime -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey --hostname valkey-site1-server-1 --name valkey-site1-server-1 valkey/valkey:9.1 valkey-server  /usr/local/etc/valkey/valkey-site1-server-1.conf --port 7001
podman run -d --rm --network=valkey -p 7002:7002 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey --hostname valkey-site1-server-2  --name valkey-site1-server-2 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site1-server-2.conf  --port 7002
podman run -d --rm --network=valkey -p 7003:7003 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey  --hostname valkey-site1-server-3  --name valkey-site1-server-3 valkey/valkey:9.1 valkey-server  /usr/local/etc/valkey/valkey-site1-server-3.conf  --port 7003

echo "Starting Site 2"

podman run -d --rm --network=valkey -p 7004:7004 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey  --hostname valkey-site2-server-1  --name valkey-site2-server-1 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site2-server-1.conf  --port 7004
podman run -d --rm --network=valkey -p 7005:7005 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey  --hostname valkey-site2-server-2  --name valkey-site2-server-2 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site2-server-2.conf  --port 7005
podman run -d --rm --network=valkey -p 7006:7006 -v $PWD/runtime:/usr/local/etc/valkey-runtime  -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey  --hostname valkey-site2-server-3  --name valkey-site2-server-3 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site2-server-3.conf  --port 7006
```


Create cluster

```shell
podman exec -it valkey-site1-server-1 valkey-cli --cluster create valkey-site1-server-1:7001 valkey-site1-server-2:7002  valkey-site1-server-3:7003 valkey-site2-server-1:7004 valkey-site2-server-2:7005 valkey-site2-server-3:7006  --cluster-replicas 1
```


Start Spring in New Terminal

```shell
java -jar applications/customer-service/target/customer-service-0.0.1-SNAPSHOT.jar --spring.profiles.active=clustering --server.port=8070
```



```shell
./deployments/local/scripts/user-loop-test.sh
```


Interact with the cluster


```shell
podman exec -it valkey-site2-server-3 valkey-cli -c -p 7006 -h 127.0.0.1
```

```shell
CLUSTER NODES
```

View Cluster Details 

```shell
CLUSTER INFO
```


Crash site 1

```shell
podman rm  -f valkey-site1-server-1 valkey-site1-server-2 valkey-site1-server-3
```


Repair Cluster

```shell
podman exec -it valkey-site2-server-1 valkey-cli -p 7004 CLUSTER FAILOVER TAKEOVER
podman exec -it valkey-site2-server-2 valkey-cli -p 7005 CLUSTER FAILOVER TAKEOVER

podman exec -it valkey-site2-server-3 valkey-cli -p 7006 CLUSTER FAILOVER TAKEOVER
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
podman run -d --rm --network=valkey  -v $PWD/runtime:/usr/local/etc/valkey-runtime -v $PWD/deployments/local/valkey/config/multi-site/2-sites:/usr/local/etc/valkey --hostname valkey-site1-server-1 --name valkey-site1-server-1 valkey/valkey:9.1 valkey-server /usr/local/etc/valkey/valkey-site1-server-1.conf
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
podman rm  -f valkey-site2-server-3
```

```shell
podman exec -it valkey-site1-server-3 valkey-cli -p 7003
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
podman exec -it valkey-site1-server-3 valkey-cli --cluster check valkey-site1-server-3:7003
podman exec -it valkey-site2-server-1 valkey-cli --cluster check valkey-site2-server-1:7004
podman exec -it valkey-site2-server-2 valkey-cli --cluster check valkey-site2-server-2:7005
```


```shell
podman exec -it valkey-site2-server-1 valkey-cli --cluster fix valkey-site2-server-1:7004  --cluster-fix-with-unreachable-primaries
```


-------------------

# Cleanup 
```shell
podman rm -f valkey-site1-server-1 valkey-site1-server-2 valkey-site1-server-3 valkey-site2-server-1 valkey-site2-server-2 valkey-site2-server-3 

rm runtime/*.conf
```