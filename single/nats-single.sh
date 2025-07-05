#!/bin/bash

# Script de gestión del servidor NATS Single con TLS
# Uso: ./nats-single.sh [start|stop|restart|status|logs|clean|test|info]

set -e

COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="nats-single-tls"
SERVICE_NAME="nats-single-tls"

function show_usage() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start     - Iniciar el servidor NATS con TLS"
    echo "  stop      - Detener el servidor"
    echo "  restart   - Reiniciar el servidor"
    echo "  status    - Ver estado del contenedor"
    echo "  logs      - Ver logs del servidor"
    echo "  shell     - Acceso shell al contenedor"
    echo "  clean     - Limpiar datos de JetStream"
    echo "  test      - Probar conexión TLS"
    echo "  info      - Mostrar información del servidor"
    echo "  backup    - Hacer backup de JetStream"
    echo "  restore   - Restaurar backup de JetStream"
    echo ""
}

function start_server() {
    echo "🚀 Iniciando servidor NATS Single con TLS..."
    
    # Verificar que existen los certificados
    if [ ! -f "./certs/server-cert.pem" ]; then
        echo "⚠️  Certificados TLS no encontrados. Generando..."
        generate_certificates
    fi
    
    # Crear directorios si no existen
    mkdir -p ./data/jetstream ./logs
    
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo "✅ Servidor iniciado!"
    echo ""
    echo "Conexiones disponibles:"
    echo "- TLS: tls://admin:medflow2025@localhost:4222"
    echo "- WebSocket TLS: wss://admin:medflow2025@localhost:8080"
    echo ""
    echo "Interfaces web:"
    echo "- Monitoreo HTTP: http://localhost:8222"
    echo "- Health Check: http://localhost:8222/healthz"
    echo ""
    echo "Para probar la conexión: $0 test"
}

function stop_server() {
    echo "🛑 Deteniendo servidor NATS..."
    docker-compose -f "$COMPOSE_FILE" down
    echo "✅ Servidor detenido!"
}

function restart_server() {
    echo "🔄 Reiniciando servidor NATS..."
    stop_server
    sleep 2
    start_server
}

function show_status() {
    echo "📊 Estado del servidor NATS Single con TLS:"
    echo ""
    docker-compose -f "$COMPOSE_FILE" ps
    echo ""
    
    # Verificar conectividad
    echo "🔍 Verificando conectividad:"
    if curl -s --max-time 2 http://localhost:8222/varz > /dev/null 2>&1; then
        echo "✅ Servidor NATS está activo"
        
        # Mostrar información básica
        echo ""
        echo "📈 Información del servidor:"
        curl -s http://localhost:8222/varz | jq -r '
            "   Versión: " + .version,
            "   Uptime: " + .uptime,
            "   Conexiones: " + (.connections | tostring),
            "   TLS: " + (if .tls_required then "✅ Requerido" else "❌ No requerido" end),
            "   JetStream: " + (if .jetstream then "✅ Habilitado" else "❌ Deshabilitado" end)
        ' 2>/dev/null || echo "   (jq no disponible para mostrar detalles)"
    else
        echo "❌ Servidor NATS no responde"
    fi
}

function show_logs() {
    echo "📋 Logs del servidor NATS:"
    docker-compose -f "$COMPOSE_FILE" logs -f "$SERVICE_NAME"
}

function shell_access() {
    echo "🐚 Accediendo al shell del contenedor..."
    docker exec -it "$CONTAINER_NAME" /bin/sh
}

function clean_data() {
    echo "🧹 Limpiando datos de JetStream..."
    read -p "⚠️  Esto eliminará todos los datos de JetStream. ¿Continuar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_server
        rm -rf ./data/jetstream/*
        rm -rf ./logs/*
        echo "✅ Datos limpiados!"
    else
        echo "❌ Operación cancelada"
    fi
}

function generate_certificates() {
    echo "🔐 Generando certificados TLS..."
    if [ -f "./generate-certs.sh" ]; then
        ./generate-certs.sh
    else
        echo "❌ Script generate-certs.sh no encontrado"
        exit 1
    fi
    echo "✅ Certificados generados!"
}

function test_connection() {
    echo "🔍 Probando conexión TLS..."
    
    # Verificar que el servidor esté corriendo
    if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo "❌ El servidor no está corriendo. Usa: $0 start"
        exit 1
    fi
    
    # Esperar a que el servicio esté listo
    echo "⏳ Esperando a que el servicio esté listo..."
    sleep 3
    
    # Test básico con curl
    echo "🌐 Probando endpoint HTTP..."
    if curl -s --max-time 5 http://localhost:8222/varz | grep -q "server_name"; then
        echo "✅ HTTP endpoint está activo"
    else
        echo "❌ HTTP endpoint no responde"
    fi
    
    # Test de health check
    echo "🏥 Probando health check..."
    if curl -s --max-time 5 http://localhost:8222/healthz | grep -q "ok"; then
        echo "✅ Health check exitoso"
    else
        echo "❌ Health check falló"
    fi
    
    echo ""
    echo "🔐 Para probar TLS con NATS CLI:"
    echo "nats context save single-tls \\"
    echo "  --server tls://localhost:4222 \\"
    echo "  --user admin \\"
    echo "  --password medflow2025 \\"
    echo "  --tlsca ./certs/ca-cert.pem \\"
    echo "  --tlscert ./certs/client-cert.pem \\"
    echo "  --tlskey ./certs/client-key.pem"
    echo ""
    echo "nats context select single-tls"
    echo "nats server info"
    echo "nats stream ls"
}

function show_info() {
    echo "ℹ️  Información del servidor NATS Single con TLS:"
    echo ""
    echo "📁 Archivos de configuración:"
    echo "- docker-compose.yml"
    echo "- nats-server-tls.conf"
    echo ""
    echo "🔐 Certificados TLS:"
    echo "- CA: ./certs/ca-cert.pem"
    echo "- Servidor: ./certs/server-cert.pem"
    echo "- Cliente: ./certs/client-cert.pem"
    echo ""
    echo "📊 Puertos:"
    echo "- NATS TLS: 4222"
    echo "- HTTP Monitor: 8222"
    echo "- WebSocket TLS: 8080"
    echo ""
    echo "👥 Usuarios configurados:"
    echo "- admin: Permisos completos"
    echo "- service: Permisos de servicios (events.>, services.>)"
    echo "- client: Permisos de aplicación (app.>, client.>)"
    echo ""
    echo "💾 Almacenamiento:"
    echo "- JetStream: ./data/jetstream"
    echo "- Logs: ./logs"
}

function backup_data() {
    echo "💾 Creando backup de JetStream..."
    
    if [ ! -d "./data/jetstream" ]; then
        echo "❌ No hay datos para respaldar"
        exit 1
    fi
    
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    local backup_dir="./backups/$backup_name"
    
    mkdir -p "$backup_dir"
    cp -r ./data/jetstream "$backup_dir/"
    
    # Crear archivo de información del backup
    cat > "$backup_dir/backup-info.txt" <<EOF
Backup creado: $(date)
Servidor: NATS Single TLS
Directorio original: ./data/jetstream
EOF
    
    echo "✅ Backup creado en: $backup_dir"
    echo "Para restaurar: $0 restore $backup_name"
}

function restore_data() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        echo "❌ Especifica el nombre del backup"
        echo "Backups disponibles:"
        ls -1 ./backups/ 2>/dev/null || echo "  (ninguno)"
        exit 1
    fi
    
    local backup_dir="./backups/$backup_name"
    
    if [ ! -d "$backup_dir" ]; then
        echo "❌ Backup no encontrado: $backup_dir"
        exit 1
    fi
    
    echo "🔄 Restaurando backup: $backup_name"
    read -p "⚠️  Esto sobrescribirá los datos actuales. ¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_server
        rm -rf ./data/jetstream/*
        cp -r "$backup_dir/jetstream/"* ./data/jetstream/
        echo "✅ Backup restaurado!"
        echo "Reinicia el servidor para aplicar los cambios"
    else
        echo "❌ Restauración cancelada"
    fi
}

# Procesar comando
case "${1:-}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    shell)
        shell_access
        ;;
    clean)
        clean_data
        ;;
    test)
        test_connection
        ;;
    info)
        show_info
        ;;
    backup)
        backup_data
        ;;
    restore)
        restore_data "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
