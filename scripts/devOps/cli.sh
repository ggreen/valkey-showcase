export VALKEY_CERT_PATH=/Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/runtime/etc/valkey/valkey-certs
valkey-cli -h 192.168.86.210 -p 6379 --tls \
  --cacert $VALKEY_CERT_PATH/ca.crt \
  --cert $VALKEY_CERT_PATH/valkey.crt \
  --key $VALKEY_CERT_PATH/valkey.key