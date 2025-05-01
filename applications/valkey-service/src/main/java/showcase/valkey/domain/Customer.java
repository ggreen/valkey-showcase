package showcase.valkey.domain;


import lombok.Builder;

@Builder
public record Customer(String id, String first_name, String last_name, String email) {
}
