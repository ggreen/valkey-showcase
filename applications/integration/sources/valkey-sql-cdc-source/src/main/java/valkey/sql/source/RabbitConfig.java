package valkey.sql.source;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {


    @Bean
    @ConditionalOnProperty(value = "spring.cloud.stream.bindings.output.destination")
    TopicExchange topicExchange(@Value("${spring.cloud.stream.bindings.output.destination}") String exchangeName, RabbitTemplate amqpTemplate) {

        amqpTemplate.setExchange(exchangeName);
        return new TopicExchange(exchangeName);
    }
}
