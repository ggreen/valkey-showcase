package showcase.valkey;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.repository.configuration.EnableRedisRepositories;

@Configuration
@EnableRedisRepositories
public class ValKeyConfig {

    Environment env;
    public ValKeyConfig(Environment env) {
        this.env = env;
    }

}
