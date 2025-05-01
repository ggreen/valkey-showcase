package spring.valkey.integration.sink.consumer;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.function.Consumer;

@Component
@Slf4j
public class ValKeyConsumer implements Consumer<String> {

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final String idField;
    private final String keyPrefix;

    public ValKeyConsumer(RedisTemplate<String, String> redisTemplate,
                          @Value("${valKey.consumer.key.field:id}") String idField,
                          @Value("${valKey.consumer.key.prefix:ValKeyConsumer-}")String keyPrefix) {
        this.redisTemplate = redisTemplate;
        this.idField = idField;
        this.keyPrefix = keyPrefix;
    }

    @SneakyThrows
    @Override
    public void accept(String payload) {
      log.info("payload: {}",payload);

        var jsonNodes = objectMapper.readTree(payload);

        String id = jsonNodes.get(idField).asText();
        log.info("key with prefix: {}{}):",keyPrefix,id);
        String key = keyPrefix+id;

        redisTemplate.opsForValue().set(key,payload);
    }
}
