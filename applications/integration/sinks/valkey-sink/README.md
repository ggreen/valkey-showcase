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



Spring Properties

```properties
valKey.consumer.key.prefix:ValKeyConsumer-
valKey.consumer.key.field:id
```

Connection Properties

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
spring.data.redis.username=
spring.data.redis.password=
spring.data.redis.url=
spring.data.redis.connect-timeout=
spring.data.redis.client-type=lettuce
```
