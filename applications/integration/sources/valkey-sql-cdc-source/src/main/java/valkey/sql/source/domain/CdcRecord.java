package valkey.sql.source.domain;

import lombok.Builder;

import java.sql.Timestamp;

@Builder
public record CdcRecord(String id, String lastRowId, long lastTimestamp) {
}
