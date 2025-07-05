#!/bin/bash

# Script para generar certificados TLS para NATS Server
# Este script crea una CA (Certificate Authority) y certificados para el servidor

set -e

CERT_DIR="./certs"
CA_KEY="$CERT_DIR/ca-key.pem"
CA_CERT="$CERT_DIR/ca-cert.pem"
SERVER_KEY="$CERT_DIR/server-key.pem"
SERVER_CERT="$CERT_DIR/server-cert.pem"
CLIENT_KEY="$CERT_DIR/client-key.pem"
CLIENT_CERT="$CERT_DIR/client-cert.pem"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Crear directorio de certificados si no existe
if [ ! -d "$CERT_DIR" ]; then
    print_status "Creando directorio de certificados: $CERT_DIR"
    mkdir -p "$CERT_DIR"
fi

# Verificar si openssl está instalado
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL no está instalado. Por favor, instálalo primero."
    exit 1
fi

print_status "Generando certificados TLS para NATS Server..."

# 1. Generar clave privada de la CA
print_status "Generando clave privada de la CA..."
openssl genrsa -out "$CA_KEY" 4096

# 2. Generar certificado de la CA
print_status "Generando certificado de la CA..."
openssl req -new -x509 -key "$CA_KEY" -sha256 -subj "/C=US/ST=CA/O=NATS/CN=NATS-CA" -days 3650 -out "$CA_CERT"

# 3. Generar clave privada del servidor
print_status "Generando clave privada del servidor..."
openssl genrsa -out "$SERVER_KEY" 4096

# 4. Crear CSR (Certificate Signing Request) para el servidor
print_status "Generando CSR del servidor..."
openssl req -new -key "$SERVER_KEY" -out "$CERT_DIR/server.csr" -subj "/C=US/ST=CA/O=NATS/CN=nats-server"

# 5. Crear archivo de configuración para extensiones del servidor
cat > "$CERT_DIR/server.conf" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
O = NATS
CN = nats-server

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = nats-server
DNS.3 = nats
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# 6. Generar certificado del servidor firmado por la CA
print_status "Generando certificado del servidor..."
openssl x509 -req -in "$CERT_DIR/server.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$SERVER_CERT" -days 365 -extensions v3_req -extfile "$CERT_DIR/server.conf"

# 7. Generar clave privada del cliente
print_status "Generando clave privada del cliente..."
openssl genrsa -out "$CLIENT_KEY" 4096

# 8. Crear CSR para el cliente
print_status "Generando CSR del cliente..."
openssl req -new -key "$CLIENT_KEY" -out "$CERT_DIR/client.csr" -subj "/C=US/ST=CA/O=NATS/CN=nats-client"

# 9. Generar certificado del cliente
print_status "Generando certificado del cliente..."
openssl x509 -req -in "$CERT_DIR/client.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$CLIENT_CERT" -days 365

# Limpiar archivos temporales
rm -f "$CERT_DIR/server.csr" "$CERT_DIR/client.csr" "$CERT_DIR/server.conf" "$CERT_DIR/ca-cert.srl"

# Establecer permisos apropiados
chmod 600 "$CA_KEY" "$SERVER_KEY" "$CLIENT_KEY"
chmod 644 "$CA_CERT" "$SERVER_CERT" "$CLIENT_CERT"

print_status "Certificados generados exitosamente en el directorio: $CERT_DIR"
print_status "Archivos creados:"
echo "  - Autoridad Certificadora:"
echo "    - $CA_KEY (clave privada)"
echo "    - $CA_CERT (certificado)"
echo "  - Servidor:"
echo "    - $SERVER_KEY (clave privada)"
echo "    - $SERVER_CERT (certificado)"
echo "  - Cliente:"
echo "    - $CLIENT_KEY (clave privada)"
echo "    - $CLIENT_CERT (certificado)"

print_warning "IMPORTANTE: Mantén las claves privadas seguras y no las compartas."
print_status "Los certificados son válidos por 1 año (365 días)."

# Verificar certificados generados
print_status "Verificando certificados..."
echo "Verificando certificado del servidor:"
openssl x509 -in "$SERVER_CERT" -text -noout | grep -E "(Subject:|DNS:|IP Address:)"
echo ""
echo "Verificando certificado del cliente:"
openssl x509 -in "$CLIENT_CERT" -text -noout | grep "Subject:"
