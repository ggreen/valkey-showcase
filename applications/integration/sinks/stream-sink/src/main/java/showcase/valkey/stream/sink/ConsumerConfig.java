package showcase.valkey.stream.sink;

import io.valkey.Jedis;
import io.valkey.StreamEntryID;
import io.valkey.params.XReadParams;
import io.valkey.resps.StreamEntry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

@Configuration
@Slf4j
public class ConsumerConfig {

    @Value("${valkey.stream.name}")
    private String streamName;

    @Value("${valkey.consumer.stream.count}")
    private int count;

    @Bean
    CommandLineRunner runner(Jedis jedis, Consumer<List<Map.Entry<String, List<StreamEntry>>>>  consumer){

        return args -> {
            // Create XReadParams (1 message, block indefinitely = 0 ms)
            XReadParams xReadParams = XReadParams.xReadParams().count(count).block(0);
            // Reading entries from the stream: must pass Map<String, StreamEntryID>
            consumer.accept(
                        jedis.xread(xReadParams, Map.of(streamName, new StreamEntryID("0-0"))));

        };
    }

    @Bean
    Consumer<List<Map.Entry<String, List<StreamEntry>>>> consumer(Jedis jedis){
        return result -> {
            log.info("Results: {}",result);

            for (var stream : result) {
                log.info("Stream: {}", stream.getKey());
                for (StreamEntry entry : stream.getValue()) {
                    log.info("ID: {}, Fields: {}",entry.getID(), entry.getFields());
                }
            }
        };
    }
}
