

```shell
podman  network  create valkey

```


```shell
mkdir -p $PWD/runtime
```


Start Servers



```shell
echo "Starting Site 1 Nodes"

podman run -d --rm \
  --network=valkey \
  -p 7011:7011 \
  --hostname site1-node1 \
  --name site1-node1 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7011 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes --cluster-announce-ip site1-node1 

podman run -d --rm \
  --network=valkey \
  -p 7012:7012 \
  --hostname site1-node2 \
  --name site1-node2 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7012 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes   --cluster-announce-ip site1-node2 

echo "Starting Site 2 Nodes"

podman run -d --rm \
  --network=valkey \
  -p 7021:7021 \
  --hostname site2-node1 \
  --name site2-node1 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7021 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes   --cluster-announce-ip site2-node1 

podman run -d --rm \
  --network=valkey \
  -p 7022:7022 \
  --hostname site2-node2 \
  --name site2-node2 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7022 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes --cluster-announce-ip site2-node2 

echo "Starting Site 3 Witness Nodes"

podman run -d --rm \
  --network=valkey \
  -p 7031:7031 \
  --hostname site3-witness1 \
  --name site3-witness1 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7031 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes   --cluster-announce-ip site3-witness1 

podman run -d --rm \
  --network=valkey \
  -p 7032:7032 \
  --hostname site3-witness2 \
  --name site3-witness2 \
  docker.io/valkey/valkey:9.1 \
  valkey-server --port 7032 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes   --cluster-announce-ip site3-witness2 
```


Create cluster (the order of nodes asserts that primaries and replicas are not on the same site)

```shell
podman exec -it site1-node1 valkey-cli --cluster create site1-node1:7011 site2-node1:7021  site3-witness1:7031  site3-witness2:7032  site1-node2:7012 site2-node2:7022  --cluster-replicas 1
```


Start Spring in New Terminal
```shell
java -jar applications/customer-service/target/customer-service-0.0.1-SNAPSHOT.jar --spring.profiles.active=witness-clustering --server.port=8070
```


Start script

```shell
deployments/local/scripts/user-loop-test.sh
```


View Cluster Details 


```shell
podman exec -it site3-witness2 valkey-cli -p 7032 
```



```shell
CLUSTER INFO
```




Crash site 1

```shell
podman rm  -f site1-node1 site1-node2
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


Kill  Site 1

```shell
podman rm  -f site1-node1 site1-node2
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
podman rm -f site1-node1 site1-node2 site2-node1 site2-node2 site3-witness1 site3-witness2 
```