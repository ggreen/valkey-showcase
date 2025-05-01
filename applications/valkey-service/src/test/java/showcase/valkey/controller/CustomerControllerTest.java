package showcase.valkey.controller;

import nyla.solutions.core.patterns.creational.generator.JavaBeanGeneratorCreator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import showcase.valkey.domain.Customer;
import showcase.valkey.repository.CustomerRepository;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;


@ExtendWith(MockitoExtension.class)
class CustomerControllerTest {


    private CustomerController subject;
    private Customer customer = JavaBeanGeneratorCreator.of(Customer.class).create();

    @Mock
    private CustomerRepository customerRepository;

    @BeforeEach
    void setUp() {
        subject = new CustomerController(customerRepository);
    }

    @Test
    void save() {
        subject.save(customer);
        verify(customerRepository).save(any());
    }

    @Test
    void findCustomerById() {

        when(customerRepository.findById(any())).thenReturn(Optional.of(customer));

        var actual = subject.findCustomerById(customer.id());
        assertThat(actual).isEqualTo(customer);
    }
}