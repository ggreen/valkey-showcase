package valkey.sql.source.publisher;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.core.Message;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class AmqpConsumerPublisherTest {

    private AmqpConsumerPublisher subject;
    private String payload = "junit";
    @Mock
    private AmqpTemplate template;

    @BeforeEach
    void setUp() {
        subject = new AmqpConsumerPublisher(template);
    }

    @Test
    void accept() {
        subject.accept(payload);

        verify(template).send(any(Message.class));
    }
}