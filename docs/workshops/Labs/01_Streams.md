# ValKey Streams

This workshop is focus on ValKey Streams


## Getting Started


Start Valkey

```shell
./deployments/local/valkey/valkey-start.sh
```

Start Source application

```shell
java -jar applications/integration/sources/stream-source/target/stream-source-0.0.1-SNAPSHOT.jar --server.port=8064  --valkey.stream.name=stream
```


Start ValKey CLI

```shell
./deployments/local/valkey/valkey-cli.sh
```


# Labs

Add a stream with key "stream" Field=hello and Value=world
Note: * allows the server to generate a new ID

Execute in valkey-cli

```shell
XADD stream * hello world
```

Execute in valkey-cli
```shell
XADD stream * name Jill email j@mail
XADD stream * name Jack email j@mail
```

Look at length of stream

Execute in valkey-cli
```shell
XLEN stream
```

Read stream two records

Execute in valkey-cli
```shell
XRANGE stream 0-0 + COUNT 2
```


Read 100 new stream entries,
starting at the end of the stream,
and block for up to 300 ms
if no entries are being written:

Execute in valkey-cli
```shell
XREAD COUNT 100 BLOCK 9999 STREAMS stream $
```

Using MAXLEN the old entries are automatically evicted when the specified length is reached, so that the stream is left at a constant size.

Execute in valkey-cli
```shell
XADD stream MAXLEN 2 * firstName John lastName Smith
```
Execute in valkey-cli
```shell
XRANGE stream 0-0 + COUNT 10
```

## Applications

Build application

```shell
mvn package
```



Get number of items in a stream

Execute in valkey-cli
```shell
XLEN stream
```

Add Records

Post  10 Messages in shell
```shell
for i in {1..10}; do
  echo $i
  curl -X POST http://localhost:8064/functions/publish \
       -H "Content-Type: application/json" \
       -d '{"key": "$i", "value": "Hi $1"}'
done
```


Get number of items in a stream

Execute in valkey-cli
```shell
XLEN stream
```

Run Consumer Sink Application

```shell
java -jar applications/integration/sinks/stream-sink/target/stream-sink-0.0.1-SNAPSHOT.jar --valkey.consumer.stream.count=10  --valkey.stream.name=stream
```


Post  10 Messages in shell
```shell
for i in {1..10}; do
  echo $i
  curl -X POST http://localhost:8064/functions/publish \
       -H "Content-Type: application/json" \
       -d "{\"key\": \"key$i\", \"value\": \"Hi $i\"}"       
done
```

View logs in the Consumer Sink Application