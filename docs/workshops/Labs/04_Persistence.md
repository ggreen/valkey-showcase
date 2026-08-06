# Valkey Persistence Workshop

## Overview

This workshop will walk system engineers through Valkey's persistence mechanisms using practical, hands-on steps. You'll learn how to enable, configure, and test both **RDB (snapshotting)** and **AOF (Append Only File)** persistence modes.

See https://valkey.io/topics/persistence/

## Prerequisites

- Docker or Podman installed
- Basic understanding of Redis/Valkey commands
- Shell access to your system
- Text editor (e.g., `vim`, `nano`, `code`)

---

# 1. What is Valkey Persistence?

Valkey offers two main persistence options:

| Mode | Description                                                   |
|------|---------------------------------------------------------------|
| RDB  | Point-in-time snapshots saved to disk at configured intervals |
| AOF  | Every write operation is logged and replayed at startup       |

You can use **RDB only**, **AOF only**, or **both** depending on durability and performance requirements.

---

# 2. Setting Up Valkey in Docker

### Step 1: Create a volume to persist data

```bash
podman volume create valkey-data
```

Step 2: Run Valkey with persistence config
```shell
podman run -d --rm --name valkey -v valkey-data:/data \
-p 6379:6379  valkey/valkey
```


# 3. Hands-On with RDB Persistence



Step 1: View Snapshot

```shell
podman exec -it valkey valkey-cli CONFIG GET save
```

Example output
```shell
 GET save
1) "save"
2) "3600 1 300 100 60 10000"
```

Save every 3600 secs at least 1 writes
Save every 300 secs at least 100 writes
Save every 60 secs at least 10000 writes

Step 2: Connect to Valkey CLI

```bash
podman exec -it valkey valkey-cli
```


Step 3: Add some data

```valkey-cli
SET user:1000 "Alice"
SET user:1001 "Bob"
```

Step 4: Trigger a manual save

```valkey-cli
SAVE
```

This creates an dump.rdb file in /data.

Step 4: Check RDB file


```bash
podman exec -it valkey ls -lh /data/dump.rdb
```

Step 5: Restart and verify persistence

```shell
podman restart valkey
podman exec -it valkey valkey-cli GET user:1000
```

# 4. Enable and Test AOF Persistence

Step 1: Stop the running container

```shell
podman rm -f  valkey
```

Step 2: Run Valkey with AOF enabled

```shell
podman run -d --name valkey-aof \
  -v valkey-data:/data \
  -p 6379:6379 \
  valkey/valkey \
  valkey-server --appendonly yes
```


Step 3: Add new data

```shell
podman exec -it valkey-aof valkey-cli SET user:1002 "John"
```

Step 4: View the AOF file

```shell
podman exec -it valkey-aof ls -lh /data/appendonlydir
```

View content in append file

```shell
podman exec -it valkey-aof cat /data/appendonlydir/appendonly.aof.1.incr.aof
```

Step 5: Simulate crash and recovery

```shell
podman kill valkey-aof
podman start valkey-aof
podman exec -it valkey-aof valkey-cli GET user:1002
```


Clean up

```shell
podman rm -f valkey-aof
```

# 5. Bonus: Combined RDB + AOF

To enable both modes:


automatically save the dataset to disk 
every 900 seconds if at least 1 key has changed.

Also save writ

```shell
podman run -d --name valkey-combo \
  -v valkey-data:/data \
  -p 6379:6379 \
  valkey/valkey \
  valkey-server --save "900 1" --appendonly yes
```


# 6. Cleanup

```shell
podman rm -f valkey valkey-aof valkey-combo
podman volume rm valkey-data
```


# Summary 

## RDB (Valkey Database)

By default Valkey saves snapshots of the dataset on disk, in a binary file called dump.rdb. 

- You can configure Valkey to have it save the dataset every N seconds if there are at least M changes in the dataset,


## Append-only file 

Every time Valkey receives a command that changes the dataset.
When you restart Valkey it will re-play the AOF to rebuild the state.

Notes
- The AOF gets bigger and bigger as write operations are performed.
- appendfsync always        # fsync every write (safest, slowest)
- appendfsync everysec      # fsync once per second (good balance)
- appendfsync no            # let OS flush data (fastest, riskier)


| Mode | Durability | Startup Speed | File Size |
|------|------------|---------------|-----------|
| RDB  | Lower      | Fast          | Compact   |
| AOF  | Higher     | Slower        | Larger    |
