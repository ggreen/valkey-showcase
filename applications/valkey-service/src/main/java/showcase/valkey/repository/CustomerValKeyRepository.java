package showcase.valkey.repository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.valkey.HostAndPort;
import io.valkey.JedisClientConfig;
import io.valkey.JedisPool;
import io.valkey.params.ScanParams;
import lombok.SneakyThrows;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;
import showcase.valkey.domain.Customer;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;


@Repository
public class CustomerValKeyRepository implements CrudRepository<Customer,String> {
    private final JedisPool valkeyPool;
    private final ObjectMapper objectMapper;
    private static final String prefix = "customer-";
    private static final String prefixMatch = prefix+"*";
    private static final String cursor = "0";
    private static final ScanParams params = new ScanParams();;

    public CustomerValKeyRepository(HostAndPort hostAndPort, JedisClientConfig config, ObjectMapper objectMapper)
    {
        this.objectMapper = objectMapper;
        valkeyPool = new io.valkey.JedisPool(hostAndPort,config);

    }

    private String toKey(String id) {
        return prefix.concat(id);
    }

    @SneakyThrows
    @Override
    public Customer save(Customer customer) {

        try(var valkey = valkeyPool.getResource())
        {
            valkey.set(toKey(customer.id()),objectMapper.writeValueAsString(customer));
        }
        return customer;
    }

    @Override
    public <S extends Customer> Iterable<S> saveAll(Iterable<S> customers) {
        ArrayList<S> list = new ArrayList<>();

        for (var customer : customers)
            list.add((S) save(customer));

        return list;
    }

    @SneakyThrows
    @Override
    public Optional<Customer> findById(String id) {

        var formattedId = toKey(id);

        return readById(formattedId);
    }

    private Optional<Customer> readById(String formattedId) throws JsonProcessingException {
        try(var valkey = valkeyPool.getResource())
        {
            var customerJson = valkey.get(formattedId);

            if(customerJson == null || customerJson.isEmpty())
                return null;

            return Optional.of(objectMapper.readValue(customerJson, Customer.class));
        }
    }

    @Override
    public boolean existsById(String id) {
        return this.findById(id).isEmpty();
    }

    @SneakyThrows
    @Override
    public Iterable<Customer> findAll() {

        List<Customer> list = new ArrayList<>();
        try(var valkey = valkeyPool.getResource())
        {
            var keys = valkey.scan(cursor,params.match(prefixMatch));
            if(keys == null)
                return null;

            var results = keys.getResult();
            if (results ==null || results.isEmpty())
                return null;

            for(var id : results)
            {
                list.add(readById(id).get());
            }
        }

        return list;
    }

    @Override
    public Iterable<Customer> findAllById(Iterable<String> customerIds) {

        var list = new ArrayList<Customer>();

        for (var customerId : customerIds)
        {
            var customer = findById(customerId);
            if(customer.isEmpty())
                continue;

            list.add(customer.get());
        }
        return list;
    }

    @Override
    public long count() {
        try(var valkey = valkeyPool.getResource())
        {
            return valkey.dbSize();
        }
    }

    @Override
    public void deleteById(String id) {
        try(var valkey = valkeyPool.getResource())
        {
            valkey.del(toKey(id));
        }
    }

    @Override
    public void delete(Customer entity) {
        deleteById(entity.id());
    }

    @Override
    public void deleteAllById(Iterable<? extends String> ids) {
        for(var id : ids)
            deleteById(id);
    }

    @Override
    public void deleteAll(Iterable<? extends Customer> customers) {
        for(var customer : customers)
            deleteById(customer.id());
    }

    @Override
    public void deleteAll() {

        try(var valkey = valkeyPool.getResource())
        {
            String cursor = "0";
            ScanParams params = new ScanParams();
            var keys = valkey.scan(cursor,params);
            if(keys == null)
                return;

            var results = keys.getResult();
            if (results ==null )
                return;

            for(var key : results)
            {
                valkey.del(key);
            }
        }
    }
}
