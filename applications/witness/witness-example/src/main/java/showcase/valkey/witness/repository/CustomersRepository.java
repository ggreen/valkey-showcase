package showcase.valkey.witness.repository;

import io.cloudNativeData.valkey.demo.domains.Customer;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;
import showcase.valkey.witness.service.ValkeySlotRouter;
import tools.jackson.databind.json.JsonMapper;

import java.time.Duration;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class CustomersRepository {

    private final StringRedisTemplate redisTemplate;
    private final ValkeySlotRouter slotRouter;
    private final JsonMapper jsonMapper;


    @SneakyThrows
    public void save(Customer customer) {
        // 1. Generate a mathematically safe key
        var safeKey = slotRouter.generateSafeKey(customer.id(), ":session");

        var jsonData = jsonMapper.writeValueAsString(customer);
        // 2. Write to Valkey using the safe key
        redisTemplate.opsForValue().set(safeKey, jsonData, Duration.ofHours(2));
    }

    @SneakyThrows
    public Optional<Customer> findById(String userId) {
        // The read path must use the exact same logic to resolve the mutated key
        var safeKey = slotRouter.generateSafeKey(userId, ":session");
        var jsonData = redisTemplate.opsForValue().get(safeKey);
        if(jsonData == null || jsonData.isEmpty()) Optional.empty();

        return Optional.of(jsonMapper.readValue(jsonData, Customer.class));
    }
}
