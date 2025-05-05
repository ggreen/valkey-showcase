package valkey.sql.source.runner;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class SqlRunner implements ApplicationRunner{

    private final JdbcTemplate jdbcTemplate;

    private final PreparedStatementCreator preparedStatementCreator;
    private final RowCallbackHandler rowCallbackHandler;


    @Override
    public void run(ApplicationArguments args) throws Exception {
        execute();
    }
    @Scheduled(cron = "${cdc.source.schedule.cron}")
    public void  execute(){
        jdbcTemplate.query(preparedStatementCreator,rowCallbackHandler);
    }
}
