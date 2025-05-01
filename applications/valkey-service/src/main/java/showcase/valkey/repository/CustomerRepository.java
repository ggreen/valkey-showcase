package showcase.valkey.repository;

import org.springframework.data.repository.CrudRepository;
import showcase.valkey.domain.Customer;

public interface CustomerRepository extends CrudRepository<Customer,String> {
}
