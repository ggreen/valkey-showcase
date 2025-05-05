package valkey.sql.source;

import nyla.solutions.core.patterns.jdbc.ResultSetToMapConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JdbcConfig {

    @Value("${spring.datasource.url}")
    private String dataSourceUrl;

    @Value("${spring.datasource.username")
    private String dataSourceUsername;

    @Value("${spring.datasource.password")
    private String dataSourcePassword;

    @Bean
    ResultSetToMapConverter convert()
    {
        return new ResultSetToMapConverter();
    }
}
