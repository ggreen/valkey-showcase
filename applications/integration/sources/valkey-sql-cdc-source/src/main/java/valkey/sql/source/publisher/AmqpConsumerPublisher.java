package valkey.sql.source.publisher;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.function.Consumer;

@Component
@RequiredArgsConstructor
@Slf4j
public class AmqpConsumerPublisher implements Consumer<String> {

    private final AmqpTemplate template;

    @Override
    public void accept(String payload) {

        log.info("Sending PAYLOAD : {}",payload);

        template.send(MessageBuilder.
                withBody(payload.getBytes(StandardCharsets.UTF_8))
                .build());

        log.info("Sent");
    }
}
