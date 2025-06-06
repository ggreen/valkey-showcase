package showcase.valkey.stream.sink;

import io.valkey.Jedis;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ValKeyConfig {

    @Value("${valkey.host:localhost}")
    private String host;

    @Value("${valkey.port:6379}")
    private int port;

    @Bean
    Jedis jedis()
    {
        return new Jedis(host, port);
    }
}

