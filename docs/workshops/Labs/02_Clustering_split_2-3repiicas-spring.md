# Valkey 2-Site Cluster Setup & Failover Simulation


## Prerequisites

- Podman installed and running 
- Java 17+ runtime installed 
- Pre-built application JAR at applications/customer-service/target/customer-service-0.0.1-SNAPSHOT.jar

Add the following to /etc/hosts

```text
127.0.0.1    valkey-server-7011
127.0.0.1    valkey-server-7012
127.0.0.1    valkey-server-7013
127.0.0.1    valkey-server-7014
127.0.0.1    valkey-server-7015
127.0.0.1    valkey-server-7016
127.0.0.1    valkey-server-7021
127.0.0.1    valkey-server-7022
127.0.0.1    valkey-server-7023
127.0.0.1    valkey-server-7024
127.0.0.1    valkey-server-7025
127.0.0.1    valkey-server-7026
```

# Workshop 

## 1. Environment Preparation
   Create a dedicated Podman network and a local directory for runtime data:

```shell
podman  network  create valkey

mkdir $PWD/runtime
```


## 2. Start Valkey Nodes

Launch 6 Valkey server containers split across two simulated sites:

- Site 1: Ports 7001–7003 
- Site 2: Ports 7004–7006

```shell
echo "Starting Site 1" 

echo "starting Node 11"

podman run -d --rm --network=valkey -p 7011:7011 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-11 --name valkey-server-7011   valkey/valkey:9.1 valkey-server --port 7011 --cluster-announce-hostname "valkey-server-7011" --cluster-preferred-endpoint-type hostname --cluster-enabled yes


echo "starting Node 12"
podman run -d --rm --network=valkey -p 7012:7012 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7012 --name valkey-server-7012 valkey/valkey:9.1 valkey-server --port 7012 --cluster-announce-hostname "valkey-server-7012" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 13"
podman run -d --rm --network=valkey -p 7013:7013 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7013 --name valkey-server-7013 valkey/valkey:9.1 valkey-server --port 7013 --cluster-announce-hostname "valkey-server-7013" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 14"
podman run -d --rm --network=valkey -p 7014:7014 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7014 --name valkey-server-7014 valkey/valkey:9.1 valkey-server --port 7014 --cluster-announce-hostname "valkey-server-7014" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 15"
podman run -d --rm --network=valkey -p 7015:7015 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7015 --name valkey-server-7015 valkey/valkey:9.1 valkey-server --port 7015 --cluster-announce-hostname "valkey-server-7015" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 16"
podman run -d --rm --network=valkey -p 7016:7016 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7016 --name valkey-server-7016 valkey/valkey:9.1 valkey-server --port 7016 --cluster-announce-hostname "valkey-server-7016" --cluster-preferred-endpoint-type hostname --cluster-enabled yes


echo "---------------------------------------"

echo "Starting Site 2"

echo "starting Node 21"

podman run -d --rm --network=valkey -p 7021:7021 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7021 --name valkey-server-7021   valkey/valkey:9.1 valkey-server --port 7021 --cluster-announce-hostname "valkey-server-7021" --cluster-preferred-endpoint-type hostname --cluster-enabled yes


echo "starting Node 22"
podman run -d --rm --network=valkey -p 7022:7022 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7022 --name valkey-server-7022 valkey/valkey:9.1 valkey-server --port 7022 --cluster-announce-hostname "valkey-server-7022" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 23"
podman run -d --rm --network=valkey -p 7023:7023 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7023 --name valkey-server-7023 valkey/valkey:9.1 valkey-server --port 7023 --cluster-announce-hostname "valkey-server-7023" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 24"
podman run -d --rm --network=valkey -p 7024:7024 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7024 --name valkey-server-7024 valkey/valkey:9.1 valkey-server --port 7024 --cluster-announce-hostname "valkey-server-7024" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 25"
podman run -d --rm --network=valkey -p 7025:7025 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7025 --name valkey-server-7025 valkey/valkey:9.1 valkey-server --port 7025 --cluster-announce-hostname "valkey-server-7025" --cluster-preferred-endpoint-type hostname --cluster-enabled yes

echo "starting Node 26"
podman run -d --rm --network=valkey -p 7026:7026 -v $PWD/runtime:/usr/local/etc/valkey-runtime --hostname valkey-server-7026 --name valkey-server-7026 valkey/valkey:9.1 valkey-server --port 7026 --cluster-announce-hostname "valkey-server-7026" --cluster-preferred-endpoint-type hostname --cluster-enabled yes
```


## 3. Initialize the Cluster

Join the 6 individual nodes into a cluster with 1 replica per primary:

```shell
podman exec -it valkey-server-7011 valkey-cli  -p 7011 --cluster create valkey-server-7011:7011 valkey-server-7012:7012 valkey-server-7013:7013 valkey-server-7014:7014 valkey-server-7015:7015 valkey-server-7016:7016 valkey-server-7021:7021 valkey-server-7022:7022 valkey-server-7023:7023 valkey-server-7024:7024 valkey-server-7025:7025 valkey-server-7026:7026  --cluster-replicas 3 --cluster-yes
```


```shell
podman run --network=valkey  --rm -d --name valkey-check -v "$(pwd)/deployments/local/scripts/2-sites/split-brain-failover-detection-generic.sh:/scripts/split-brain-failover-detection-generic.sh:ro,Z" valkey/valkey:9.1

podman exec -it valkey-check bash /scripts/split-brain-failover-detection-generic.sh
```


## 4. Run the Application & Load Test

Start Spring Boot Service
In a new terminal window, launch the application using the clustering profile:

```shell
java -jar applications/customer-service/target/customer-service-0.0.1-SNAPSHOT.jar --spring.profiles.active=3replics --server.port=8070
```


Start Test Loop
In your main terminal, execute the test script to continuously perform read/write events:

```shell
./deployments/local/scripts/user-loop-test.sh
```


## 5. Inspect Cluster Health

Connect to a cluster node and run diagnostic commands:


```shell
podman exec -it valkey-server-7016 valkey-cli -c -p 7016 -h 127.0.0.1
```
Inside the valkey-cli prompt:

```shell
CLUSTER NODES
```

View Cluster Details 

```shell
CLUSTER INFO
```


## 6. Simulate Site Failure & Failover


Partial Failure Site

Simulate a complete outage of Site 1 by abruptly stopping its containers:

```shell
podman rm  -f valkey-server-7011
```

```shell
podman rm  -f valkey-server-7012
```


```shell
podman rm  -f valkey-server-7013
```


View Cluster Details (state=0k)

```shell
CLUSTER INFO
```

Verify new locations of primaries

```shell
CLUSTER NODES
```


Force-Crash Site 2

Simulate a complete outage of Site 2 by abruptly stopping its container. This resist in only 3 nodes remaining.

```shell
podman rm  -f valkey-server-7021 valkey-server-7022 valkey-server-7023 valkey-server-7024 valkey-server-7025 valkey-server-7026
 ```

Note: script get Internal Server

Example Errors

    Getting customer 03...
    {"timestamp":"2026-08-12T20:12:31.481+00:00","status":500,"error":"Internal Server Error","path":"/customers/03"}



Note the detection script will eventual fix the cluster after 3 detected failures.

```shell
./deployments/local/scripts/2-sites/split-brain-failover-detection.sh
```

View will be data loss in this scenario.

![img.png](img.png)

-------------------

## 7. Cleanup
   To teardown containers and remove generated configuration/runtime files:

```shell
podman rm -f valkey-server-7011
podman rm -f valkey-server-7012
podman rm -f valkey-server-7013
podman rm -f valkey-server-7014
podman rm -f valkey-server-7015
podman rm -f valkey-server-7016
podman rm -f valkey-server-7021
podman rm -f valkey-server-7022
podman rm -f valkey-server-7023
podman rm -f valkey-server-7024
podman rm -f valkey-server-7025
podman rm -f valkey-server-7026

```

