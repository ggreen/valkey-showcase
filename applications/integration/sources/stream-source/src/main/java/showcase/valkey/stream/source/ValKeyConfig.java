package showcase.valkey.stream.source;

import io.valkey.Jedis;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ValKeyConfig {

    @Bean
    Jedis jedis()
    {
        return new Jedis("localhost", 6379);
    }
}

