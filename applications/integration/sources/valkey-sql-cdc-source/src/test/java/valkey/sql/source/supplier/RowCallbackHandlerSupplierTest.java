package valkey.sql.source.supplier;

import lombok.SneakyThrows;
import nyla.solutions.core.patterns.jdbc.ResultSetToMapConverter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import valkey.sql.source.cdc.CdcStrategy;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.util.function.Consumer;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RowCallbackHandlerSupplierTest {

    private RowCallbackHandlerSupplier subject;


    @Mock
    private ResultSet rs;
    @Mock
    private ResultSetToMapConverter mapper;
    @Mock
    private Consumer<String> messageSendConsumer;
    @Mock
    private CdcStrategy cdcStrategy;
    private int jsonColumnNamePosition = 0;
    @Mock
    private ResultSetMetaData metaData;


    @BeforeEach
    void setUp() {
        subject = new RowCallbackHandlerSupplier(mapper, messageSendConsumer, cdcStrategy, jsonColumnNamePosition);
    }

    @SneakyThrows
    @Test
    void whenSingleJsonSColumnThenSendTextAsRecord() {

        subject = new RowCallbackHandlerSupplier(mapper, messageSendConsumer, cdcStrategy, 1);
        var expected = "{}}";

        when(rs.getMetaData()).thenReturn(metaData);
        when(metaData.getColumnCount()).thenReturn(3);

        when(metaData.getColumnName(1)).thenReturn(subject.getJsonColumnName());
        when(rs.getString(1)).thenReturn(expected);

        subject.processRow(rs);

        verify(mapper, never()).convert(rs);
        verify(messageSendConsumer).accept(anyString());
        verify(cdcStrategy).update(rs);
    }

    @SneakyThrows
    @Test
    void processRow() {

        subject.processRow(rs);

        verify(messageSendConsumer).accept(anyString());
        verify(cdcStrategy).update(rs);
    }
}