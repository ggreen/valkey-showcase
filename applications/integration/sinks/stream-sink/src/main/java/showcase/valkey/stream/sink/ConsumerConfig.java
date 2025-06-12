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

import java.util.Map;
import java.util.function.Consumer;

/**
 * @author gregory green
 */
@Configuration
@Slf4j
public class ConsumerConfig {

    @Value("${valkey.stream.name}")
    private String streamName;

    @Value("${valkey.consumer.stream.count}")
    private int count;


    @Bean
    CommandLineRunner runner(Jedis jedis, Consumer<StreamEntry>  consumer) {

        return args -> {

            // Create XReadParams (1 message, block indefinitely = 0 ms)
            XReadParams xReadParams = XReadParams.xReadParams().count(100).block(0);

            //Start from beginning of stream
            StreamEntryID streamEntryID = new StreamEntryID("0-0");

            // Reading entries from the stream: must pass Map<String, StreamEntryID>
            while (true) {
                // Reading entries from the stream: must pass Map<String, StreamEntryID>

                var result = jedis.xread(xReadParams, Map.of(streamName, streamEntryID));

                for (var stream : result) {
                    for (StreamEntry entry : stream.getValue()) {
                        consumer.accept(entry);
                        streamEntryID = entry.getID(); //save entry ID
                    }
                }
            }
        };
    }


    @Bean
    Consumer<StreamEntry> consumer(Jedis jedis){
        return entry -> {
            log.info("Results id:{}, fields: {}",entry.getID(),entry.getFields());
        };
    }
}
