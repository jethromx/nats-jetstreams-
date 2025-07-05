#!/bin/bash

# Script para configurar cliente NATS con servidor Single TLS
# Requiere tener instalado nats-cli

set -e

CERTS_DIR="./certs"

echo "🔐 Configurando cliente NATS para servidor Single TLS..."

# Verificar que nats-cli esté instalado
if ! command -v nats &> /dev/null; then
    echo "❌ nats-cli no está instalado."
    echo "Instalar con: brew install nats-io/nats-tools/nats"
    echo "O descargar desde: https://github.com/nats-io/natscli/releases"
    exit 1
fi

# Verificar que existen los certificados
if [ ! -f "$CERTS_DIR/ca-cert.pem" ]; then
    echo "❌ Certificados no encontrados. Ejecuta primero: ./generate-certs.sh"
    exit 1
fi

# Configurar contexto TLS para admin
echo "👤 Configurando contexto para usuario 'admin'..."
nats context save nats-single-admin \
    --server tls://localhost:4222 \
    --user admin \
    --password medflow2025 \
    --tlsca "$CERTS_DIR/ca-cert.pem" \
    --tlscert "$CERTS_DIR/client-cert.pem" \
    --tlskey "$CERTS_DIR/client-key.pem"

# Configurar contexto TLS para service
echo "🔧 Configurando contexto para usuario 'service'..."
nats context save nats-single-service \
    --server tls://localhost:4222 \
    --user service \
    --password medflow2025 \
    --tlsca "$CERTS_DIR/ca-cert.pem" \
    --tlscert "$CERTS_DIR/client-cert.pem" \
    --tlskey "$CERTS_DIR/client-key.pem"

# Configurar contexto TLS para client
echo "📱 Configurando contexto para usuario 'client'..."
nats context save nats-single-client \
    --server tls://localhost:4222 \
    --user client \
    --password medflow2025 \
    --tlsca "$CERTS_DIR/ca-cert.pem" \
    --tlscert "$CERTS_DIR/client-cert.pem" \
    --tlskey "$CERTS_DIR/client-key.pem"

echo "✅ Configuración completada!"
echo ""
echo "Contextos creados:"
echo "- nats-single-admin (permisos completos)"
echo "- nats-single-service (events.>, services.>)"
echo "- nats-single-client (app.>, client.>)"
echo ""
echo "Para usar los contextos:"
echo "nats context select nats-single-admin"
echo "nats server info"
echo ""
echo "Comandos de prueba:"
echo "# Como admin (puede todo)"
echo "nats pub test.message 'Hello Single TLS World!'"
echo "nats sub test.message"
echo ""
echo "# Como service (solo events.* y services.*)"
echo "nats context select nats-single-service"
echo "nats pub events.user.login '{\"user\":\"john\", \"timestamp\":\"$(date)\"}'"
echo "nats sub events.>"
echo ""
echo "# Como client (solo app.* y client.*)"
echo "nats context select nats-single-client"
echo "nats pub app.notification 'New message received'"
echo "nats sub app.>"
