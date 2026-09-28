package showcase.valkey.witness;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import tools.jackson.databind.json.JsonMapper;

@Configuration
public class SerializationConfig {
    @Bean
    JsonMapper jsonMapper()
    {
        return new JsonMapper();
    }
}
