## Start ValKey

Run the following to create a  network for the ValKey locator and server members to communicate.


Run the following to Start a ValKey

```shell
./deployments/local/valkey/valkey-start.sh
```


Connect CLI

```shell
./deployments/local/valkey/valkey-cli.sh
```

Set a String

```shell
SET customer:jdoe "John Doe"
```

Get a String

```shell
GET customer:jdoe
```

Update

```shell
SET customer:jdoe "John Doe - (updated)"
```


Get a String (updated)

```shell
GET customer:jdoe
```

Delete a String

```shell
DEL customer:jdoe
```


Get a String (REMOVED)

```shell
GET customer:jdoe
```

# Expiring Keys

Expire in 10 seconds
```shell
SET customer:jdoe:session "Apple is your favorite fruit"
EXPIRE customer:jdoe:session 30
```

Check TTL (Time to Live): return number of seconds remaining

```shell
TTL customer:jdoe:session
```

Get a String (will be removed after 30 seconds)

```shell
GET customer:jdoe:session
```

-------------

# Working with Data Structures

## Strings

```shell
SET customers:count 100
INCR customers:count
GET customers:count
```


## Lists

```shell
LPUSH customers:waiting:list "jdoe"
LPUSH customers:waiting:list "jsmith"
RPUSH customers:waiting:list "pjohn"
```

Show list start at first entry with no upper bound (-1)

```shell
LRANGE customers:waiting:list 0 -1
```

Remove 1 item from front (left) 

```shell
LPOP customers:waiting:list 1
```

## Sets

```shell
SADD customers:remote:set "jdoe" "jsmith" "jdoe" "jdoe"
```

Returns all members of a set

```shell
SMEMBERS customers:remote:set
```

Check if key exists in set

```shell
SISMEMBER customers:remote:set "jdoe"
```

## Hashes

```shell
HSET customer:awalker firstName "Alice" lastName "Walker" age "30"
```

Get all

```shell
HGETALL customer:awalker
```

Get Specific fied

```shell
HGET customer:awalker lastName
```


## Sorted Sets


Adds one or more members to a sorted set based on scores.

```shell
ZADD customer:priorities 100 "jsmith" 200 "awalker" 150 "zoe"
```

List scored with scores

```shell
ZRANGE customer:priorities 0 -1 WITHSCORES
```


# Key Management

List keys

```shell
SCAN 0 
```

List keys based on the key match

```shell
SCAN 0 MATCH "c*"
```

Check If Key Exists

```shell
EXISTS customer:jdoe
```


## Clearing Data

Current database

```shell
FLUSHDB   
```

All databases

```shell
FLUSHALL  
```
