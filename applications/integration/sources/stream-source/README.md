# stream-source


Consumer application to send  ValKey stream messages


## Getting Started

Run Source

```shell
java -jar applications/integration/sources/stream-source/target/stream-source-0.0.1-SNAPSHOT.jar --server.port=8064  --valkey.stream.name=stream
```

Open Swagger UI

```shell
open http://localhost:8064
```

Post Message

```shell
curl -X 'POST' \
  'http://localhost:8064/functions/publish' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "key": "hello",
  "value": "world"
}'
```