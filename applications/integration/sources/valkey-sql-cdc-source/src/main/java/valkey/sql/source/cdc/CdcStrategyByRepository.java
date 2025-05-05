package valkey.sql.source.cdc;

import lombok.SneakyThrows;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import valkey.sql.source.domain.CdcRecord;
import valkey.sql.source.repository.CdcRecordRepository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.Optional;

@Component
public class CdcStrategyByRepository implements CdcStrategy{

    private static final Logger log = LoggerFactory.getLogger(CdcStrategyByRepository.class);
    private final int lastRowIdWherePosition;
    private final int lastTimestampWherePosition;
    private final String cdcId;
    private final String sqlSelectWithFrom;
    private final String sqlSqlWhereClause;
    private final  String lastRowIdSelectColumnName;
    private final  String lastTimestampSelectColumnName;

    private final CdcRecordRepository repository;

    public CdcStrategyByRepository(
            @Value("${cdc.source.jdbc.lastRowIdWherePosition}")
            int lastRowIdWherePosition,
            @Value("${cdc.source.jdbc.lastTimestampWherePosition}")
            int lastTimestampWherePosition,
            @Value("${cdc.source.jdbc.cdcId}")
            String cdcId,
            @Value("${cdc.source.jdbc.sqlSelectWithFrom}")
            String sqlSelectWithFrom,
            @Value("${cdc.source.jdbc.sqlSqlWhereClause}")
            String sqlSqlWhereClause,
            @Value("${cdc.source.jdbc.lastRowIdSelectColumnName}")
            String lastRowIdSelectColumnName,
            @Value("${cdc.source.jdbc.lastTimestampSelectColumnName}")
            String lastTimestampSelectColumnName,
            CdcRecordRepository repository) {

        this.cdcId = cdcId;
        this.repository = repository;
        this.sqlSelectWithFrom = sqlSelectWithFrom;
        this.sqlSqlWhereClause = sqlSqlWhereClause;
        this.lastRowIdSelectColumnName = lastRowIdSelectColumnName;
        this.lastRowIdWherePosition = lastRowIdWherePosition;
        this.lastTimestampSelectColumnName = lastTimestampSelectColumnName;
        this.lastTimestampWherePosition = lastTimestampWherePosition;

    }

    @SneakyThrows
    @Override
    public void update(ResultSet rs) {

        var rowId = rs.getString(lastRowIdSelectColumnName);
        var rowTimestamp = rs.getTimestamp(lastTimestampSelectColumnName);

        log.info("Searching by rowId {} rowTimestamp {}",rowId,rowTimestamp);

        var results  = repository.findById(cdcId);

        //New record
        if(results.isEmpty())
        {
            var builder = CdcRecord.builder().id(cdcId)
                    .lastRowId(rowId);

            if(rowTimestamp != null)
                builder.lastTimestamp(rowTimestamp.getTime());

            log.info("Saving CDC new rowId {} rowTimestamp {}",rowId,rowTimestamp);
            repository.save(
                    builder.build());

            return;
        }

        var cdc = results.get();

        log.info("Found cdc record : {}",cdc);

        //check if newer
        var saveCdcBuilder = CdcRecord.builder()
                .id(cdc.id())
                .lastTimestamp(cdc.lastTimestamp())
                .lastRowId(cdc.lastRowId());

        if(rowTimestamp != null && rowTimestamp.getTime() > cdc.lastTimestamp())
        {
            //cdc .lastTimestamp() = rowTimestamp;
            saveCdcBuilder.lastTimestamp(rowTimestamp.getTime());
        }

        if(rowId != null && !rowId.equals(cdc.lastRowId()))
        {
            //cdc.lastRowId = rowId
            saveCdcBuilder.lastRowId(rowId);
        }

        var saveCdc = saveCdcBuilder.build();

        log.info("Saving cdc record : {}",saveCdc);
        repository.save(saveCdc);

    }

    @SneakyThrows
    public PreparedStatement createPreparedStatement(Connection connection){

        var cdcReport = repository.findById(cdcId);

        var sql = getSql(cdcReport);

        log.info("SQL {}",sql);

        var ps = connection.prepareStatement(sql);

        if(cdcReport.isPresent())
        {
            var cdc = cdcReport.get();
            log.info("Found CDC report {}",cdc);

            ps.setString(lastRowIdWherePosition, cdc.lastRowId());
            ps.setTimestamp(lastTimestampWherePosition, new Timestamp(cdc.lastTimestamp()));

            log.info("Set rowId:{} timestamp: {}",cdc.lastRowId(),cdc.lastTimestamp());
        }

        return ps;
    }

    /**
     * Retrieve the SQL based on he cdc
     * @param cdc the CDC data
     * @return the formatted SQL select
     */
    public String getSql(Optional<CdcRecord> cdc) {

        if(cdc.isEmpty())
            return sqlSelectWithFrom;

        var sql = sqlSelectWithFrom+" "+sqlSqlWhereClause;

        log.info("SQL {}",sql);
        return sql;
    }
}
