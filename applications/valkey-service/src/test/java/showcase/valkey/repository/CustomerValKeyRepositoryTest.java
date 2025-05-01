package showcase.valkey.repository;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.valkey.DefaultJedisClientConfig;
import io.valkey.HostAndPort;
import io.valkey.JedisClientConfig;
import nyla.solutions.core.patterns.creational.generator.JavaBeanGeneratorCreator;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.GenericContainer;
import showcase.valkey.domain.Customer;

import static java.util.Arrays.asList;
import static org.assertj.core.api.Assertions.assertThat;

class CustomerValKeyRepositoryTest {

    private static GenericContainer redis;
    private static Integer port = 6379;
    private CustomerValKeyRepository subject;
    private Customer customer = JavaBeanGeneratorCreator.of(Customer.class).create();
    private  HostAndPort hostPort;
    private JedisClientConfig config;
    private ObjectMapper objectMapper = new ObjectMapper();


    @BeforeAll
    static void beforeAll() {
        redis = new GenericContainer<>("bitnami/valkey:8.0.2")
                .withExposedPorts(port);
    }

    @AfterAll
    static void afterAll() {
        redis.close();
    }

    @BeforeEach
    void setUp() {
        hostPort = HostAndPort.from("127.0.0.1:"+port);
        config = DefaultJedisClientConfig.builder()
                .build();

        subject = new CustomerValKeyRepository(hostPort,config,objectMapper);
    }


    @Test
    void findAll() {
        create_read();

        var actual = subject.findAll();

        assertThat(actual).isNotEmpty();
    }

    @Test
    void findAllById() {
        var creator = JavaBeanGeneratorCreator.of(Customer.class);

        var customer1 = creator.create();
        var customer2 = creator.create();

        var list = asList(customer1,customer2);
        subject.saveAll(list);

        var actual = subject.findAllById(asList(customer1.id(),customer2.id()));

        assertThat(actual).isNotEmpty();
    }

    @Test
    void create_read() {

        var expected = subject.save(customer);
        assertThat(expected).isNotNull();

        assertThat(expected).isEqualTo(subject.findById(customer.id()).get());
    }

    @Test
    void update() {
        create_read();

        var expected = Customer.builder()
                .id(customer.id())
                .email(customer.email())
                .firstName(customer.first_name()+"UPDATED")
                .lastName(customer.last_name()+"UPDATED")
                .build();

        subject.save(expected);

        var actual = subject.findById(expected.id());
        assertThat(expected).isEqualTo(actual.get());
    }

    @Test
    void delete() {
        create_read();

        subject.deleteById(customer.id());

        assertThat(subject.findById(customer.id())).isNull();
    }

    @Test
    void deleteAll() {

        create_read();

        subject.deleteAll();

        assertThat(subject.findById(customer.id())).isNull();
    }

    @Test
    void count() {
        this.deleteAll();

        var creator = JavaBeanGeneratorCreator.of(Customer.class);

        var customer1 = creator.create();
        var customer2 = creator.create();

        var list = asList(customer1,customer2);
        subject.saveAll(list);

        var actual = subject.count();
        var expected = list.stream().count();


        assertThat(actual).isEqualTo(expected);
    }

    @Test
    void save() {
        var expected = subject.save(customer);
        assertThat(expected).isNotNull();

        assertThat(expected).isEqualTo(subject.findById(customer.id()).get());
    }
}