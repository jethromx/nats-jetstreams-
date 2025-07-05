#!/bin/bash

# Script para manejar el cluster NATS

case "$1" in
    start)
        echo "Iniciando cluster NATS..."
        docker-compose up -d
        echo "Cluster iniciado. Puertos disponibles:"
        echo "- NATS Node 1: 4222 (HTTP: 8222)"
        echo "- NATS Node 2: 4223 (HTTP: 8223)"
        echo "- NATS Node 3: 4224 (HTTP: 8224)"
        ;;
    stop)
        echo "Deteniendo cluster NATS..."
        docker-compose down
        ;;
    restart)
        echo "Reiniciando cluster NATS..."
        docker-compose restart
        ;;
    logs)
        if [ -z "$2" ]; then
            docker-compose logs -f
        else
            docker-compose logs -f "nats-node-$2"
        fi
        ;;
    status)
        echo "Estado del cluster:"
        docker-compose ps
        ;;
    clean)
        echo "Limpiando datos del cluster..."
        docker-compose down -v
        sudo rm -rf ./jetstream_data/node-*/
        mkdir -p ./jetstream_data/node-{1,2,3}
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|logs [1|2|3]|status|clean}"
        echo ""
        echo "Comandos:"
        echo "  start   - Inicia el cluster NATS"
        echo "  stop    - Detiene el cluster NATS"
        echo "  restart - Reinicia el cluster NATS"
        echo "  logs    - Muestra logs (opcional: especifica nodo 1, 2 o 3)"
        echo "  status  - Muestra el estado de los contenedores"
        echo "  clean   - Limpia todos los datos y contenedores"
        exit 1
        ;;
esac
