#!/bin/bash

# Script de gestión del cluster NATS con TLS
# Uso: ./nats-cluster-tls.sh [start|stop|status|logs|clean|certs]

set -e

COMPOSE_FILE="docker-compose-tls.yml"
PROJECT_NAME="nats-cluster-tls"

function show_usage() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start     - Iniciar el cluster NATS con TLS"
    echo "  stop      - Detener el cluster"
    echo "  restart   - Reiniciar el cluster"
    echo "  status    - Ver estado de los contenedores"
    echo "  logs      - Ver logs de todos los nodos (o específico: logs 1|2|3)"
    echo "  clean     - Limpiar datos de JetStream"
    echo "  certs     - Regenerar certificados TLS"
    echo "  test      - Probar conexión TLS"
    echo "  info      - Mostrar información del cluster"
    echo ""
}

function start_cluster() {
    echo "🚀 Iniciando cluster NATS con TLS..."
    
    # Verificar que existen los certificados
    if [ ! -f "./certs/server-cert.pem" ]; then
        echo "⚠️  Certificados TLS no encontrados. Generando..."
        generate_certificates
    fi
    
    # Crear directorio de logs si no existe
    mkdir -p ./logs
    
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    echo "✅ Cluster iniciado!"
    echo ""
    echo "Conexiones disponibles:"
    echo "- TLS: tls://admin:medflow2025@localhost:4222"
    echo "- TLS: tls://admin:medflow2025@localhost:4223"
    echo "- TLS: tls://admin:medflow2025@localhost:4224"
    echo ""
    echo "Monitoreo Web:"
    echo "- Node 1: http://localhost:8222"
    echo "- Node 2: http://localhost:8223"
    echo "- Node 3: http://localhost:8224"
    echo ""
    echo "Para probar la conexión: $0 test"
}

function stop_cluster() {
    echo "🛑 Deteniendo cluster NATS..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
    echo "✅ Cluster detenido!"
}

function restart_cluster() {
    echo "🔄 Reiniciando cluster NATS..."
    stop_cluster
    sleep 2
    start_cluster
}

function show_status() {
    echo "📊 Estado del cluster NATS con TLS:"
    echo ""
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    echo ""
    
    # Verificar conectividad de cada nodo
    echo "🔍 Verificando conectividad:"
    for port in 4222 4223 4224; do
        if curl -s --max-time 2 http://localhost:$((port + 4000))/varz > /dev/null 2>&1; then
            echo "✅ Nodo en puerto $port está activo"
        else
            echo "❌ Nodo en puerto $port no responde"
        fi
    done
}

function show_logs() {
    local node="$1"
    
    if [ -z "$node" ]; then
        echo "📋 Logs de todos los nodos:"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f
    else
        case "$node" in
            1)
                echo "📋 Logs del nodo 1:"
                docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f nats-node-1-tls
                ;;
            2)
                echo "📋 Logs del nodo 2:"
                docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f nats-node-2-tls
                ;;
            3)
                echo "📋 Logs del nodo 3:"
                docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f nats-node-3-tls
                ;;
            *)
                echo "❌ Nodo inválido. Usa: 1, 2 o 3"
                exit 1
                ;;
        esac
    fi
}

function clean_data() {
    echo "🧹 Limpiando datos de JetStream..."
    read -p "⚠️  Esto eliminará todos los datos de JetStream. ¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_cluster
        rm -rf ./jetstream_data/*/jetstream/
        rm -rf ./logs/*
        echo "✅ Datos limpiados!"
    else
        echo "❌ Operación cancelada"
    fi
}

function generate_certificates() {
    echo "🔐 Generando certificados TLS..."
    ./generate-tls-certs.sh
    echo "✅ Certificados generados!"
}

function test_connection() {
    echo "🔍 Probando conexión TLS..."
    
    # Verificar que el cluster esté corriendo
    if ! docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps | grep -q "Up"; then
        echo "❌ El cluster no está corriendo. Usa: $0 start"
        exit 1
    fi
    
    # Esperar a que los servicios estén listos
    echo "⏳ Esperando a que los servicios estén listos..."
    sleep 5
    
    # Test básico con curl a los endpoints HTTP
    echo "🌐 Probando endpoints HTTP..."
    for port in 8222 8223 8224; do
        if curl -s --max-time 5 http://localhost:$port/varz | grep -q "server_name"; then
            echo "✅ HTTP endpoint :$port está activo"
        else
            echo "❌ HTTP endpoint :$port no responde"
        fi
    done
    
    echo ""
    echo "🔐 Para probar TLS con NATS CLI:"
    echo "nats context save tls-test \\"
    echo "  --server tls://localhost:4222 \\"
    echo "  --user admin \\"
    echo "  --password medflow2025 \\"
    echo "  --tlsca ./certs/ca-cert.pem \\"
    echo "  --tlscert ./certs/client-cert.pem \\"
    echo "  --tlskey ./certs/client-key.pem"
    echo ""
    echo "nats context select tls-test"
    echo "nats server info"
}

function show_info() {
    echo "ℹ️  Información del cluster NATS con TLS:"
    echo ""
    echo "📁 Archivos de configuración:"
    echo "- docker-compose-tls.yml"
    echo "- nats-node-1-tls.conf"
    echo "- nats-node-2-tls.conf"
    echo "- nats-node-3-tls.conf"
    echo ""
    echo "🔐 Certificados TLS:"
    echo "- CA: ./certs/ca-cert.pem"
    echo "- Servidor: ./certs/server-cert.pem"
    echo "- Cliente: ./certs/client-cert.pem"
    echo ""
    echo "📊 Puertos:"
    echo "- NATS TLS: 4222, 4223, 4224"
    echo "- HTTP Monitor: 8222, 8223, 8224"
    echo "- Cluster: 6222, 6223, 6224"
    echo ""
    echo "👥 Usuarios configurados:"
    echo "- admin: Permisos completos"
    echo "- service: Permisos limitados (events.>)"
}

# Procesar comando
case "${1:-}" in
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    restart)
        restart_cluster
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    clean)
        clean_data
        ;;
    certs)
        generate_certificates
        ;;
    test)
        test_connection
        ;;
    info)
        show_info
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
