package showcase.valkey.stream.source.domain;

import lombok.Builder;

@Builder
public record StreamPayload(String key,String value) {
}
