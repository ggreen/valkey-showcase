package valkey.sql.source.repository;

import org.springframework.data.keyvalue.repository.KeyValueRepository;
import org.springframework.stereotype.Repository;
import valkey.sql.source.domain.CdcRecord;

@Repository
public interface CdcRecordRepository extends KeyValueRepository<CdcRecord,String> {
}
