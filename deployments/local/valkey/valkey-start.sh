podman run --rm -d --name valkey-server \
    -e ALLOW_EMPTY_PASSWORD=yes \
     -p 6379:6379 \
    valkey/valkey:8.1


#podman run -it --rm \
#        -e VALKEY_PRIMARY_HOST=valkey-server \
#         -p 26379:26379 \
#        bitnami/valkey-sentinel:8.0.2