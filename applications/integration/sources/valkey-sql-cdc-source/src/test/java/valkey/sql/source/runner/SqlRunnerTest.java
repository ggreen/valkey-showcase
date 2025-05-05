package valkey.sql.source.runner;

import lombok.SneakyThrows;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.ApplicationArguments;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.core.RowCallbackHandler;
import valkey.sql.source.runner.SqlRunner;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class SqlRunnerTest {

    private SqlRunner subject;
    @Mock
    private ApplicationArguments args;
    @Mock
    private JdbcTemplate jdbcTemplate;
    @Mock
    private RowCallbackHandler rowCallbackHandler;

    @Mock
    private PreparedStatementCreator preparedStatementCreator;

    @BeforeEach
    void setUp() {
        subject = new SqlRunner(jdbcTemplate,preparedStatementCreator,rowCallbackHandler);
    }

    @SneakyThrows
    @Test
    void run() {
        
        subject.run(args);
        
        verify(jdbcTemplate).query(any(PreparedStatementCreator.class),any(RowCallbackHandler.class));
    }
}