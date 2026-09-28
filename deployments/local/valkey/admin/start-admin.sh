podman run -it --rm --network=valkey \
  -p 8081:8080 \
  -e VALKEY_HOST="valkey-site1-server-1" \
  -e VALKEY_PORT="7001" \
  --name valkey-admin \
  ghcr.io/valkey-io/valkey-admin:latest