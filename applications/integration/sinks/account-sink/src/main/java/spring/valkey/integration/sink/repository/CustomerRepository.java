package spring.valkey.integration.sink.repository;

import org.springframework.data.keyvalue.repository.KeyValueRepository;
import org.springframework.stereotype.Repository;
import spring.valkey.integration.sink.domain.Customer;

@Repository
public interface CustomerRepository extends KeyValueRepository<Customer, String> {
}
