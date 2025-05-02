package showcase.valkey.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import showcase.valkey.domain.Customer;
import showcase.valkey.repository.CustomerRepository;

@RestController
@RequestMapping("customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerRepository customerRepository;

    @PostMapping
    public void save(Customer customer) {
        customerRepository.save(customer);
    }

    @GetMapping("{id}")
    public Customer findCustomerById(@PathVariable String id) {
        return customerRepository.findById(id).orElse(null);
    }
}
