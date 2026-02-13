#!/usr/bin/env bash

set -e

echo "==== Self-signed CA + server certificate generator ===="

CN="127.0.0.1"
IP="127.0.0.1"
CERT_DIR="/opt/nginx/conf/certs"

mkdir -p "$CERT_DIR"

OPENSSL_CNFG="$CERT_DIR/openssl.conf"

cat > "$OPENSSL_CNFG" <<EOF
[ req ]
default_bits       = 4096
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
C  = PT
ST = State
L  = City
O  = MyOrg
OU = MyUnit
CN = ${CN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = ${IP}

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:true
EOF

echo "🔐 Generating root CA (ca.pem)..."
openssl req -x509 -nodes -days 3650 \
  -newkey rsa:4096 \
  -keyout "$CERT_DIR/ca.key" \
  -out "$CERT_DIR/ca.pem" \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=MyUnit/CN=LocalCA" \
  -extensions v3_ca

echo "🔐 Generating server key..."
openssl genrsa -out "$CERT_DIR/server.key" 4096

echo "📄 Generating CSR..."
openssl req -new -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.csr" -config "$OPENSSL_CNFG"

echo "📜 Signing certificate with CA..."
openssl x509 -req -in "$CERT_DIR/server.csr" \
  -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca.key" \
  -CAcreateserial -out "$CERT_DIR/server.crt" \
  -days 365 -extfile "$OPENSSL_CNFG" -extensions req_ext

rm "$CERT_DIR/server.csr"

echo "✅ Certificates created:"
echo "  🔸 CA certificate:                          $CERT_DIR/ca.pem"
echo "  🔸 Server certificate:                      $CERT_DIR/server.crt"
echo "  🔸 Server private key:                      $CERT_DIR/server.key"
