

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
