package showcase.valkey.stream.source;

import io.valkey.Jedis;
import io.valkey.params.XAddParams;
import lombok.extern.slf4j.Slf4j;
import nyla.solutions.core.patterns.integration.Publisher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import showcase.valkey.stream.source.domain.StreamPayload;

import java.util.Map;
import java.util.function.Consumer;

@Configuration
@Slf4j
public class PubConfig {

    @Value("${valkey.stream.name}")
    private String streamName;

    @Bean
    Publisher<Map<String,String>> producer(Jedis connection)
    {
        return message -> {
            var entryId = connection.xadd(streamName, XAddParams.xAddParams().maxLen(1000), message);
            log.info("Published stream entry with ID: {}", entryId);
        } ;
    }

    @Bean
    Consumer<StreamPayload> publish(Publisher<Map<String,String>> publisher)
    {
        return payload -> publisher.send(Map.of(payload.key(),payload.value()));
    }
}
