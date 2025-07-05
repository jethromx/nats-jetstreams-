#!/bin/bash

# Script para generar certificados TLS para el cluster NATS
# Generar certificados auto-firmados para desarrollo

set -e

CERTS_DIR="./certs"
mkdir -p "$CERTS_DIR"

# Limpiar certificados existentes
rm -f "$CERTS_DIR"/*

echo "Generando certificados TLS para el cluster NATS..."

# 1. Generar clave privada de la CA
openssl genrsa -out "$CERTS_DIR/ca-key.pem" 4096

# 2. Generar certificado de la CA
openssl req -new -x509 -key "$CERTS_DIR/ca-key.pem" -sha256 -subj "/C=ES/ST=Madrid/L=Madrid/O=MedFlow/OU=IT/CN=NATS-CA" -days 3650 -out "$CERTS_DIR/ca-cert.pem"

# 3. Generar clave privada del servidor
openssl genrsa -out "$CERTS_DIR/server-key.pem" 4096

# 4. Crear CSR del servidor
openssl req -subj "/C=ES/ST=Madrid/L=Madrid/O=MedFlow/OU=IT/CN=nats-server" -sha256 -new -key "$CERTS_DIR/server-key.pem" -out "$CERTS_DIR/server.csr"

# 5. Crear archivo de extensiones para SAN (Subject Alternative Names)
cat > "$CERTS_DIR/server-extfile.cnf" <<EOF
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = nats-node-1
DNS.3 = nats-node-2
DNS.4 = nats-node-3
DNS.5 = nats-server
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# 6. Generar certificado del servidor firmado por la CA
openssl x509 -req -in "$CERTS_DIR/server.csr" -CA "$CERTS_DIR/ca-cert.pem" -CAkey "$CERTS_DIR/ca-key.pem" -out "$CERTS_DIR/server-cert.pem" -days 365 -extensions v3_req -extfile "$CERTS_DIR/server-extfile.cnf"

# 7. Generar clave privada del cliente
openssl genrsa -out "$CERTS_DIR/client-key.pem" 4096

# 8. Crear CSR del cliente
openssl req -subj "/C=ES/ST=Madrid/L=Madrid/O=MedFlow/OU=IT/CN=nats-client" -new -key "$CERTS_DIR/client-key.pem" -out "$CERTS_DIR/client.csr"

# 9. Generar certificado del cliente firmado por la CA
openssl x509 -req -in "$CERTS_DIR/client.csr" -CA "$CERTS_DIR/ca-cert.pem" -CAkey "$CERTS_DIR/ca-key.pem" -out "$CERTS_DIR/client-cert.pem" -days 365

# Limpiar archivos temporales
rm "$CERTS_DIR/server.csr" "$CERTS_DIR/client.csr" "$CERTS_DIR/server-extfile.cnf"

# Ajustar permisos
chmod 400 "$CERTS_DIR"/*-key.pem
chmod 444 "$CERTS_DIR"/*-cert.pem "$CERTS_DIR/ca-cert.pem"

echo "✅ Certificados TLS generados exitosamente en $CERTS_DIR"
echo ""
echo "Archivos generados:"
echo "- ca-cert.pem (Certificado de la CA)"
echo "- ca-key.pem (Clave privada de la CA)"
echo "- server-cert.pem (Certificado del servidor)"
echo "- server-key.pem (Clave privada del servidor)"
echo "- client-cert.pem (Certificado del cliente)"
echo "- client-key.pem (Clave privada del cliente)"
echo ""
echo "Para verificar el certificado del servidor:"
echo "openssl x509 -in $CERTS_DIR/server-cert.pem -text -noout"
