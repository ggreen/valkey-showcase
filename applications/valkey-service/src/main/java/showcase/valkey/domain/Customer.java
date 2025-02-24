package showcase.valkey.domain;


import lombok.Builder;

@Builder
public record Customer(String id, String firstName, String lastName, String email) {
}
