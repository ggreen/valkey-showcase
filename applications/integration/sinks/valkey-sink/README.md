
Start RabbitMQ

```shell
./deployments/local/rabbitmq/start.sh
```

Register Spring Cloud DataFlow

```properties
sink.valkey-sink=file:///Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/applications/integration/sinks/valkey-sink/target/valkey-sink-0.0.1-SNAPSHOT.jar
sink.valkey-sink.bootVersion=3
#sink.valkey-sink.metadata=file:///Users/Projects/VMware/Tanzu/TanzuData/TanzuRabbitMQ/dev/tanzu-rabbitmq-event-streaming-showcase/applications/sinks/jdbc-upsert/target/jdbc-upsert-0.2.0-SNAPSHOT-metadata.jar
```
