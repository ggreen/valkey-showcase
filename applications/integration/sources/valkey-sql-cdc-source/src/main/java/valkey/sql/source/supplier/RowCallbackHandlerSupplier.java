package valkey.sql.source.supplier;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import nyla.solutions.core.patterns.jdbc.ResultSetToMapConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Component;
import valkey.sql.source.cdc.CdcStrategy;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.function.Consumer;

/**
 * Implements RowCallbackHandler to sending select statement results a messaging system
 * @author gregory green
 */
@Component
@Slf4j
public class RowCallbackHandlerSupplier implements RowCallbackHandler {

    private final ResultSetToMapConverter converter;
    private final Consumer<String> messageSendConsumer;
    private final CdcStrategy cdcStrategy;
    private ObjectMapper objectMapper = new ObjectMapper();
    private final int jsonColumnNamePosition;
    private final static String jsonColumnName = "json";

    public RowCallbackHandlerSupplier(ResultSetToMapConverter converter,
                                      Consumer<String> messageSendConsumer,
                                      CdcStrategy cdcStrategy,
                                      @Value("${cdc.source.jdbc.jsonColumnNamePosition:0}")
                                      int jsonColumnNamePosition) {
        this.converter = converter;
        this.messageSendConsumer = messageSendConsumer;
        this.cdcStrategy = cdcStrategy;
        this.jsonColumnNamePosition = jsonColumnNamePosition;
    }

    @SneakyThrows
    @Override
    public void processRow(ResultSet rs) throws SQLException {

        var metaData = rs.getMetaData();
        if(jsonColumnNamePosition > 0 && metaData != null &&  metaData.getColumnCount() > 1 )
        {
            log.info("Checking for JSON column in results at positon: $jsonColumnNamePosition ");

            var columnName = metaData.getColumnName(jsonColumnNamePosition).trim().toLowerCase();
            log.info("Checking if $columnName ==  $jsonColumnName");

            if(jsonColumnName == columnName)
            {
                var json = rs.getString(jsonColumnNamePosition);
                log.info("Sending JSON $json");

                messageSendConsumer.accept(json);
                cdcStrategy.update(rs);
                return;
            }
        }

        var map = converter.convert(rs);
        var json = objectMapper.writeValueAsString(map);

        log.info("Sending JSON {}",json);
        messageSendConsumer.accept(json);

        cdcStrategy.update(rs);
    }

    public int getJsonColumnNamePosition() {
        return jsonColumnNamePosition;
    }

    public String getJsonColumnName() {
        return jsonColumnName;
    }
}
