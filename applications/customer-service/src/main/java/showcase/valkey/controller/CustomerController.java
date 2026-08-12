package showcase.valkey.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.web.bind.annotation.*;
import showcase.valkey.domain.Customer;
import showcase.valkey.repository.CustomerRepository;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;

@RestController
@RequestMapping("customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerRepository customerRepository;
    private final LettuceConnectionFactory connectionFactory;
    private final AtomicInteger failureCount = new AtomicInteger(0);


    @PostMapping
    public void save(@RequestBody Customer customer) {
        executeWithFailureTracking(() -> customerRepository.save(customer));
    }

    @GetMapping("{id}")
    public Customer findCustomerById(@PathVariable String id) {
        return executeWithFailureTracking(() ->
                customerRepository.findById(id).orElse(null)
        );
    }

    private <T> T executeWithFailureTracking(Supplier<T> operation) {
        try {
            T result = operation.get();
            failureCount.set(0); // Reset count on successful operation
            return result;
        } catch (Exception e) {
            if (failureCount.incrementAndGet() >= 3) {
                connectionFactory.resetConnection();
//                connectionFactory.destroy();
//                connectionFactory.afterPropertiesSet(); // Re-initializes client and connection pool
//                connectionFactory.start();
                failureCount.set(0); // Reset after triggering the connection reset
            }
            throw e;
        }
    }

    private void executeWithFailureTracking(Runnable operation) {
        executeWithFailureTracking(() -> {
            operation.run();
            return null;
        });
    }
}