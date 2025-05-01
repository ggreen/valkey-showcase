package spring.valkey.integration.sink.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.function.Consumer;

import static java.lang.String.valueOf;

@Component
@Slf4j
public class ValKeyConsumer implements Consumer<Map<String,Object>> {

    private final RedisTemplate<String, Map<String,Object>> redisTemplate;
    private final String idField;
    private final String keyPrefix;

    public ValKeyConsumer(RedisTemplate<String,  Map<String,Object>> redisTemplate,
                          @Value("${valKey.consumer.key.field:id}") String idField,
                          @Value("${valKey.consumer.key.prefix:ValKeyConsumer-}")String keyPrefix) {
        this.redisTemplate = redisTemplate;
        this.idField = idField;
        this.keyPrefix = keyPrefix;
    }

    @Override
    public void accept(Map<String,Object> map) {
      log.info("Map: {}",map);

        String id = valueOf(map.get(idField));
        log.info("key with prefix: {}{}):",keyPrefix,id);
        String key = keyPrefix+id;

        redisTemplate.opsForHash().putAll(key,map);
    }
}
