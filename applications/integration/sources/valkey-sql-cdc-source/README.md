# valkey-sql-cdc-source

This Change Data Capture example uses a Spring Cloud Stream application with basic SQL configurations.
It will detect changes based on serial primary key or update timestamps in source relational databases such as Postgres.



## SCDF Register

Register Spring Cloud DataFlow using the following properties

```properties
source.valkey-sql-cdc=file:///Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/applications/integration/sources/valkey-sql-cdc-source/target/valkey-sql-cdc-source-0.0.1-SNAPSHOT.jar
source.valkey-sql-cdc.bootVersion=3
#sink.valkey-sink.metadata=file:///Users/Projects/VMware/Tanzu/TanzuData/TanzuRabbitMQ/dev/tanzu-rabbitmq-event-streaming-showcase/applications/sinks/jdbc-upsert/target/jdbc-upsert-0.2.0-SNAPSHOT-metadata.jar
```


---------------------------------------
# Docker building image

```shell
mvn install
cd applications/integration/sources/valkey-sql-cdc-source
mvn package
docker build  --platform linux/amd64,linux/arm64 -t valkey-sql-cdc-source:0.0.1-SNAPSHOT .

```

```shell
docker tag valkey-sql-cdc-source:0.0.1-SNAPSHOT cloudnativedata/valkey-sql-cdc-source:0.0.1-SNAPSHOT
docker push cloudnativedata/valkey-sql-cdc-source:0.0.1-SNAPSHOT
```
