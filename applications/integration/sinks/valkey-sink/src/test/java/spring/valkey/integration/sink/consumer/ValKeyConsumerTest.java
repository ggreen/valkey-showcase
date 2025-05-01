package spring.valkey.integration.sink.consumer;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ValKeyConsumerTest {

    private ValKeyConsumer subject;
    @Mock
    private RedisTemplate<String, String> redisTemplate;
    @Mock
    private HashOperations<String, Object, Object> hasOps;

    private String idField = "id";
    private String payload = """
            {
                "id": "001"
            }
            """;
    @Mock
    private ValueOperations<String, String> valueOps;

    @BeforeEach
    void setUp() {
        subject = new ValKeyConsumer(redisTemplate,idField,"junit-");
    }

    @Test
    void accept() {

        when(redisTemplate.opsForValue()).thenReturn(valueOps);

        subject.accept(payload);

        verify(redisTemplate).opsForValue();

    }
}