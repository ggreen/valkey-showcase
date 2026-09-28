package showcase.valkey.witness.controller;

import io.cloudNativeData.valkey.demo.domains.Customer;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import showcase.valkey.witness.repository.CustomersRepository;


@RestController
@RequestMapping("customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomersRepository customerRepository;


    @PostMapping
    public void save(@RequestBody Customer customer) {
        customerRepository.save(customer);
    }

    @GetMapping("{id}")
    public Customer findCustomerById(@PathVariable String id) {
        return customerRepository.findById(id).orElse(null);
    }
}