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


    @PostMapping
    public void save(@RequestBody Customer customer) {
        customerRepository.save(customer);
    }

    @GetMapping("{id}")
    public Customer findCustomerById(@PathVariable String id) {
        return customerRepository.findById(id).orElse(null);
    }
}