export VALKEY_HOME=/Users/Projects/solutions/cloudNativeData/showCase/dev/valkey-showcase/runtime/etc/valkey


mkdir -p $VALKEY_HOME/valkey-certs && cd $VALKEY_HOME/valkey-certs

# 1. Generate CA Private Key
openssl genrsa -out ca.key 4096

# 2. Generate CA Certificate (valid for 365 days)
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -out ca.crt \
  -subj "/C=US/ST=Local/L=Mac/O=ValkeyCA/CN=Valkey Root CA"


# 1. Generate Server Private Key
openssl genrsa -out valkey.key 2048

# 2. Create Certificate Signing Request (CSR)
openssl req -new -key valkey.key \
  -out valkey.csr \
  -subj "/C=US/ST=Local/L=Mac/O=Valkey/CN=localhost"

# 3. Create a Subject Alternative Name (SAN) config so modern TLS clients accept localhost/IPs
cat <<EOF > cert.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

# 4. Sign the Valkey Certificate with your CA
openssl x509 -req -in valkey.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out valkey.crt -days 365 -sha256 -extfile cert.ext



  sudo chmod 644 $VALKEY_HOME/valkey-certs/ca.crt
  sudo chmod 644 $VALKEY_HOME/valkey-certs/valkey.crt
  sudo chmod 600 $VALKEY_HOME/valkey-certs/valkey.key

  ls -l $VALKEY_HOME/valkey-certs


  echo -n "my_secure_password" | sha256sum | awk '{print $1}'