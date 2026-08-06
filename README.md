# valkey-showcase

Showcases caching data patterns and application development with [ValKey](http://valkey.io).

## Demos


| Demo                                                                                         | Notes                                                                                                                                                                                                                                                                         |
|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Postgres-to-ValKey-JDBC.md](docs/workshops/Labs/ingestion/Postgres-to-ValKey-JDBC.md)       | [Spring Cloud DataFlow](https://spring.io/projects/spring-cloud-dataflow) to sync data from Postgres to ValKey using Debezium with [Spring Cloud Stream Applications](https://spring.io/projects/spring-cloud-stream-applications)                                            |
| [Postgres-to-ValKey-SQL-CDC.md](docs/workshops/Labs/ingestion/Postgres-to-ValKey-SQL-CDC.md) | [Spring Cloud DataFlow](https://spring.io/projects/spring-cloud-dataflow)  to sync data from Postgres to ValKey using a [Spring Cloud Stream](https://spring.io/projects/spring-cloud-stream) [valkey-sql-cdc-source](applications/integration/sources/valkey-sql-cdc-source) |
| [stream-source](applications/integration/sources/stream-source)                              | Publisher application using ValKey Streams                                                                                                                                                                                                                                    |
| [stream-sink](applications/integration/sinks/stream-sink)                                    | Consumer application using ValKey Streams                                                                                                                                                                                                                                     |

## Labs

See the folder [[Valkey Hands On Labs](docs/workshops/Labs) for example excercises 