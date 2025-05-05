package valkey.sql.source.cdc;

import org.springframework.jdbc.core.PreparedStatementCreator;

import java.sql.ResultSet;

public interface CdcStrategy extends PreparedStatementCreator {
    void update(ResultSet rs);

}
