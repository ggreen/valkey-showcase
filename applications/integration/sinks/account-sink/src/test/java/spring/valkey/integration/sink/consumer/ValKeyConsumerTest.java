package spring.valkey.integration.sink.consumer;

import nyla.solutions.core.util.Organizer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.RedisTemplate;

import java.util.Map;

import static nyla.solutions.core.util.Organizer.toMap;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ValKeyConsumerTest {

    private ValKeyConsumer subject;
    @Mock
    private RedisTemplate<String,  Map<String,Object>> redisTemplate;
    @Mock
    private HashOperations<String, Object, Object> hasOps;

    private String idField = "id";

    @BeforeEach
    void setUp() {
        subject = new ValKeyConsumer(redisTemplate,idField,"junit-");
    }

    @Test
    void accept() {
        Map<String,Object> map = toMap("id","100",
                    "fn","first name",
                    "ln", "LastName",
                "contact",
                toMap("email","mail@"));

        when(redisTemplate.opsForHash()).thenReturn(hasOps);

        subject.accept(map);

        verify(redisTemplate).opsForHash();

    }
}