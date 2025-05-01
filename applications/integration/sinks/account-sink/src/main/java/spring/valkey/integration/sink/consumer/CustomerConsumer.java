package spring.valkey.integration.sink.consumer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import spring.valkey.integration.sink.domain.Customer;
import spring.valkey.integration.sink.repository.CustomerRepository;

import java.util.Map;
import java.util.function.Consumer;

import static java.lang.String.valueOf;

@Component
@Slf4j
@RequiredArgsConstructor
public class CustomerConsumer implements Consumer<Customer> {

    private final CustomerRepository customerRepository;

    @Override
    public void accept(Customer customer) {
        customerRepository.save(customer);
    }
}
