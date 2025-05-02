package showcase.valkey.repository;

import org.springframework.data.keyvalue.repository.KeyValueRepository;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;
import showcase.valkey.domain.Customer;

@Repository
public interface CustomerRepository extends KeyValueRepository<Customer,String> {
}
