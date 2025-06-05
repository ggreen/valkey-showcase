


Get number of items in a stream

```shell
XLEN stream
```

Read 100 new stream entries, 
starting at the end of the stream, 
and block for up to 300 ms 
if no entries are being written:

```shell
XREAD COUNT 100 BLOCK 9999 STREAMS stream $
```
