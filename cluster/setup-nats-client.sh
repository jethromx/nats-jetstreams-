#!/bin/bash

# Script para configurar cliente NATS con TLS
# Requiere tener instalado nats-cli

set -e

CERTS_DIR="./certs"

echo "🔐 Configurando cliente NATS con TLS..."

# Verificar que nats-cli esté instalado
if ! command -v nats &> /dev/null; then
    echo "❌ nats-cli no está instalado."
    echo "Instalar con: brew install nats-io/nats-tools/nats"
    echo "O descargar desde: https://github.com/nats-io/natscli/releases"
    exit 1
fi

# Verificar que existen los certificados
if [ ! -f "$CERTS_DIR/ca-cert.pem" ]; then
    echo "❌ Certificados no encontrados. Ejecuta primero: ./generate-tls-certs.sh"
    exit 1
fi

# Configurar contexto TLS para admin
echo "👤 Configurando contexto para usuario 'admin'..."
nats context save nats-tls-admin \
    --server tls://localhost:4222 \
    --user admin \
    --password medflow2025 \
    --tlsca "$CERTS_DIR/ca-cert.pem" \
    --tlscert "$CERTS_DIR/client-cert.pem" \
    --tlskey "$CERTS_DIR/client-key.pem"

# Configurar contexto TLS para service
echo "🔧 Configurando contexto para usuario 'service'..."
nats context save nats-tls-service \
    --server tls://localhost:4222 \
    --user service \
    --password medflow2025 \
    --tlsca "$CERTS_DIR/ca-cert.pem" \
    --tlscert "$CERTS_DIR/client-cert.pem" \
    --tlskey "$CERTS_DIR/client-key.pem"

echo "✅ Configuración completada!"
echo ""
echo "Para usar los contextos:"
echo "nats context select nats-tls-admin"
echo "nats server info"
echo ""
echo "nats context select nats-tls-service"
echo "nats server info"
echo ""
echo "Comandos de prueba:"
echo "nats pub test.message 'Hello TLS World!'"
echo "nats sub test.message"
