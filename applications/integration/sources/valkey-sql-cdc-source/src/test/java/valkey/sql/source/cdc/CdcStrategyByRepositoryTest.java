package valkey.sql.source.cdc;

import lombok.SneakyThrows;
import nyla.solutions.core.patterns.creational.generator.JavaBeanGeneratorCreator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import valkey.sql.source.domain.CdcRecord;
import valkey.sql.source.repository.CdcRecordRepository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CdcStrategyByRepositoryTest {

    private CdcStrategyByRepository subject;

    @Mock
    private ResultSet rs;

    @Mock
    private Connection connection;
    @Mock
    private CdcRecordRepository repository;

    @Mock
    private PreparedStatement preparedStatement;
    private CdcRecord cdcRecord = JavaBeanGeneratorCreator.of(CdcRecord.class).create();

    private String lastTimestampSelectColumnName = "col2";
    private String lastRowIdSelectColumnName = "col1";
    private String whereClause = "where a1 = ? and a2 =?";
    private String sql = "select * from table ";
    private int lastTimestampPosition = 4;
    private int lastRowIdPosition = 3;

    @Mock
    private CdcStrategy cdcStrategy;


    @BeforeEach
    void setUp() {

        subject = new CdcStrategyByRepository(
                lastRowIdPosition,
                lastTimestampPosition,
                cdcRecord.id(),
                sql,
                whereClause,
                lastRowIdSelectColumnName,
                lastTimestampSelectColumnName,
                repository
        );
    }

    @SneakyThrows
    @Test
    void update_whenPreviousRecordDoesExitsThenLastRecordNull() {
        when(rs.getString(anyString())).thenReturn(null);
        when(rs.getTimestamp(anyString())).thenReturn(null);
        when(repository.findById(anyString())).thenReturn(Optional.empty());

        subject.update(rs);

        verify(repository).save(any(CdcRecord.class));
    }


    @SneakyThrows
    @Test
    void createPreparedStatement() {
        when(connection.prepareStatement(anyString())).thenReturn(preparedStatement);

        var actual = subject.createPreparedStatement(connection);
        assertNotNull(actual);
    }


    @Test
    void getSql_whenNoLastRecord_ThenSqlDoesContainsWhere() {


//        when(repository.findById(anyString())).thenReturn(Optional.empty());
        assertTrue(!subject.getSql(Optional.empty()).contains("where"));
    }


    @Test
    void getSql_whenNoLastRecord_ThenSqlDContainsWhere() {
        assertTrue(subject.getSql(Optional.of(cdcRecord)).contains("where"));
    }
}