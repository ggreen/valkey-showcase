package showcase.valkey;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.valkey.DefaultJedisClientConfig;
import io.valkey.HostAndPort;
import io.valkey.JedisClientConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ValKeyConfig {

    @Value("${spring.data.valkey.port:6379}")
    private int port;

    @Value("${spring.data.valkey.host:localhost}")
    private String host;

    @Value("${spring.application.name:valkey-service}")
    private String applicationName;

    @Bean
    HostAndPort hostAndPort()
    {
        return new HostAndPort(host,port);
    }


    @Bean
    JedisClientConfig jedisClientConfig()
    {
        return DefaultJedisClientConfig.builder()
                .clientName(applicationName)
                .build();
    }

//    @Bean
//    ObjectMapper objectMapper()
//    {
//        return new ObjectMapper();
//    }
}
