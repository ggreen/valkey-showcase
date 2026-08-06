# Valkey Sink

Sink to store JSON data in ValKey

Start RabbitMQ

```shell
./deployments/local/rabbitmq/start.sh
```

Register Spring Cloud DataFlow

```properties
sink.valkey-sink=maven://com.github.ggreen:valkey-sink:0.0.1
sink.valkey-sink.bootVersion=3
```
