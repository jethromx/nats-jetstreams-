# Ejemplos de Uso - NATS JetStream POC

Esta guía contiene ejemplos prácticos de cómo usar las configuraciones NATS implementadas en este proyecto.

## 📋 Tabla de Contenidos

- [Configuración Inicial](#configuración-inicial)
- [Mensajería Básica](#mensajería-básica)
- [JetStream Avanzado](#jetstream-avanzado)
- [Casos de Uso Reales](#casos-de-uso-reales)
- [Monitoring y Debugging](#monitoring-y-debugging)
- [Integración con Aplicaciones](#integración-con-aplicaciones)

## 🚀 Configuración Inicial

### Inicio Rápido - Single Node

```bash
# Iniciar servidor single
cd single
./nats-single.sh start

# Configurar cliente NATS CLI
./setup-client.sh
nats context select nats-single-admin
```

### Inicio Rápido - Cluster

```bash
# Iniciar cluster con TLS
cd cluster
./nats-cluster-tls.sh start

# Configurar cliente NATS CLI
./setup-nats-client.sh
nats context select nats-tls-admin
```

## 📨 Mensajería Básica

### Publish/Subscribe Simple

```bash
# Terminal 1: Suscriptor
nats sub eventos.usuario.login

# Terminal 2: Publicador
nats pub eventos.usuario.login '{"usuario": "john", "timestamp": "2025-07-04T10:30:00Z"}'
```

### Request/Response

```bash
# Terminal 1: Responder a requests
nats reply "math.add" "echo 'Suma: $((${NATS_DATA} + 5))'"

# Terminal 2: Hacer request
nats request math.add "10"
```

### Wildcard Subscriptions

```bash
# Suscribirse a todos los eventos
nats sub "eventos.>"

# Suscribirse a eventos de usuario específico
nats sub "eventos.usuario.*"

# Publicar diferentes tipos de eventos
nats pub eventos.usuario.login '{"user":"alice"}'
nats pub eventos.usuario.logout '{"user":"alice"}'
nats pub eventos.sistema.startup '{"service":"api"}'
```

## 🏗️ JetStream Avanzado

### Crear Streams

```bash
# Stream para eventos de usuario
nats stream add EVENTOS_USUARIO \
  --subjects="eventos.usuario.>" \
  --storage=file \
  --retention=workqueue \
  --max-msgs=1000000 \
  --max-age=24h

# Stream para logs de sistema
nats stream add LOGS_SISTEMA \
  --subjects="logs.>" \
  --storage=file \
  --retention=limits \
  --max-msgs=500000 \
  --max-age=7d

# Stream para métricas
nats stream add METRICAS \
  --subjects="metrics.>" \
  --storage=memory \
  --retention=workqueue \
  --max-msgs=100000 \
  --max-age=1h
```

### Configurar Consumers

```bash
# Consumer push para procesamiento en tiempo real
nats consumer add EVENTOS_USUARIO procesador-eventos \
  --filter="eventos.usuario.>" \
  --deliver=all \
  --ack=explicit \
  --max-deliver=3

# Consumer pull para procesamiento por lotes
nats consumer add LOGS_SISTEMA analizador-logs \
  --filter="logs.error" \
  --deliver=all \
  --ack=explicit \
  --pull

# Consumer durable para servicios críticos
nats consumer add EVENTOS_USUARIO notificador-critico \
  --filter="eventos.usuario.login" \
  --deliver=new \
  --ack=explicit \
  --durable
```

### Publicar a Streams

```bash
# Evento de login
nats pub eventos.usuario.login '{
  "usuario": "alice@example.com",
  "timestamp": "'$(date -Iseconds)'",
  "ip": "192.168.1.100",
  "dispositivo": "web",
  "ubicacion": "Madrid, España"
}'

# Log de error
nats pub logs.error '{
  "nivel": "ERROR",
  "servicio": "api-auth",
  "mensaje": "Fallo en autenticación",
  "timestamp": "'$(date -Iseconds)'",
  "trace_id": "abc123xyz"
}'

# Métrica de rendimiento
nats pub metrics.api.response_time '{
  "endpoint": "/api/users",
  "tiempo_respuesta": 250,
  "timestamp": "'$(date -Iseconds)'",
  "status_code": 200
}'
```

### Consumir Mensajes

```bash
# Consumir mensajes uno por uno (pull)
nats consumer next LOGS_SISTEMA analizador-logs

# Consumir múltiples mensajes
nats consumer next LOGS_SISTEMA analizador-logs --count=10

# Suscripción push
nats consumer sub EVENTOS_USUARIO procesador-eventos
```

## 💼 Casos de Uso Reales

### 1. Sistema de Autenticación

```bash
# Crear stream para eventos de auth
nats stream add AUTH_EVENTS \
  --subjects="auth.>" \
  --storage=file \
  --retention=workqueue \
  --max-age=30d

# Consumer para auditoría
nats consumer add AUTH_EVENTS auditoria \
  --filter="auth.>" \
  --deliver=all \
  --ack=explicit

# Eventos de ejemplo
nats pub auth.login.success '{
  "user_id": "user123",
  "email": "user@example.com",
  "ip": "192.168.1.100",
  "timestamp": "'$(date -Iseconds)'"
}'

nats pub auth.login.failed '{
  "email": "hacker@evil.com",
  "ip": "10.0.0.1",
  "reason": "invalid_password",
  "timestamp": "'$(date -Iseconds)'"
}'
```

### 2. Procesamiento de Pedidos

```bash
# Stream para pedidos
nats stream add PEDIDOS \
  --subjects="pedidos.>" \
  --storage=file \
  --retention=workqueue \
  --max-msgs=1000000

# Consumers especializados
nats consumer add PEDIDOS procesador-pagos \
  --filter="pedidos.nuevo" \
  --deliver=all \
  --ack=explicit

nats consumer add PEDIDOS notificador-cliente \
  --filter="pedidos.confirmado" \
  --deliver=all \
  --ack=explicit

nats consumer add PEDIDOS gestor-inventario \
  --filter="pedidos.>" \
  --deliver=all \
  --ack=explicit

# Flujo de pedido
nats pub pedidos.nuevo '{
  "pedido_id": "PED001",
  "cliente_id": "CLI123",
  "productos": [{"id": "PROD1", "cantidad": 2}],
  "total": 99.99,
  "timestamp": "'$(date -Iseconds)'"
}'

nats pub pedidos.confirmado '{
  "pedido_id": "PED001",
  "estado": "confirmado",
  "timestamp": "'$(date -Iseconds)'"
}'
```

### 3. Microservicios Communication

```bash
# Stream para comunicación entre servicios
nats stream add SERVICIOS \
  --subjects="servicios.>" \
  --storage=file \
  --retention=workqueue \
  --max-age=1h

# Request/Response entre servicios
# Terminal 1: Servicio de usuarios responde
nats reply servicios.users.get 'echo "{\"user_id\": \"'${NATS_DATA}'\", \"name\": \"John Doe\", \"email\": \"john@example.com\"}"'

# Terminal 2: Servicio de pedidos hace request
nats request servicios.users.get "user123"
```

### 4. Real-time Notifications

```bash
# Stream para notificaciones
nats stream add NOTIFICACIONES \
  --subjects="notifications.>" \
  --storage=memory \
  --retention=workqueue \
  --max-age=15m

# Consumer para cada canal
nats consumer add NOTIFICACIONES push-notifications \
  --filter="notifications.push" \
  --deliver=new \
  --ack=explicit

nats consumer add NOTIFICACIONES email-notifications \
  --filter="notifications.email" \
  --deliver=new \
  --ack=explicit

# Enviar notificaciones
nats pub notifications.push '{
  "user_id": "user123",
  "title": "Nuevo mensaje",
  "body": "Tienes un nuevo mensaje de Alice",
  "timestamp": "'$(date -Iseconds)'"
}'

nats pub notifications.email '{
  "to": "user@example.com",
  "subject": "Confirmación de pedido",
  "template": "order_confirmation",
  "data": {"order_id": "PED001"},
  "timestamp": "'$(date -Iseconds)'"
}'
```

## 📊 Monitoring y Debugging

### Información de Streams

```bash
# Listar todos los streams
nats stream ls

# Información detallada de un stream
nats stream info EVENTOS_USUARIO

# Ver mensajes en un stream
nats stream view EVENTOS_USUARIO

# Ver últimos mensajes
nats stream view EVENTOS_USUARIO --last=10
```

### Información de Consumers

```bash
# Listar consumers de un stream
nats consumer ls EVENTOS_USUARIO

# Información detallada de un consumer
nats consumer info EVENTOS_USUARIO procesador-eventos

# Ver mensajes pendientes
nats consumer pending EVENTOS_USUARIO procesador-eventos
```

### Monitoring con HTTP API

```bash
# Información del servidor
curl -s http://localhost:8222/varz | jq '{
  server_name: .server_name,
  version: .version,
  uptime: .uptime,
  connections: .connections,
  in_msgs: .in_msgs,
  out_msgs: .out_msgs
}'

# Estado de JetStream
curl -s http://localhost:8222/jsz | jq '{
  enabled: .config.enabled,
  memory: .memory,
  storage: .storage,
  streams: .streams,
  consumers: .consumers
}'

# Información de conexiones
curl -s http://localhost:8222/connz | jq '.connections[] | {
  cid: .cid,
  name: .name,
  lang: .lang,
  subscriptions: .subscriptions_list_size
}'
```

### Benchmarking

```bash
# Test de rendimiento básico
nats bench test.performance --msgs=10000 --size=1024

# Test con múltiples publishers
nats bench test.performance --msgs=10000 --size=1024 --pub=5

# Test con JetStream
nats bench test.jetstream --msgs=10000 --size=1024 --js
```

## 🔗 Integración con Aplicaciones

### Conexión desde Python

```python
import asyncio
import json
from datetime import datetime
from nats.aio.client import Client as NATS

async def main():
    nc = NATS()
    
    # Conectar con TLS
    await nc.connect(
        servers=["tls://localhost:4222"],
        user="admin",
        password="medflow2025",
        # ... configuración TLS
    )
    
    # Publicar evento
    event = {
        "user_id": "user123",
        "action": "login",
        "timestamp": datetime.now().isoformat()
    }
    
    js = nc.jetstream()
    await js.publish("eventos.usuario.login", json.dumps(event).encode())
    
    await nc.close()

asyncio.run(main())
```

### Conexión desde Node.js

```javascript
const { connect, JSONCodec } = require('nats');

async function main() {
    const nc = await connect({
        servers: ['tls://localhost:4222'],
        user: 'admin',
        pass: 'medflow2025',
        // ... configuración TLS
    });
    
    const js = nc.jetstream();
    const jc = JSONCodec();
    
    // Publicar evento
    const event = {
        user_id: 'user123',
        action: 'login',
        timestamp: new Date().toISOString()
    };
    
    await js.publish('eventos.usuario.login', jc.encode(event));
    
    await nc.close();
}

main();
```

### Conexión desde Go

```go
package main

import (
    "encoding/json"
    "log"
    "time"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, err := nats.Connect("tls://admin:medflow2025@localhost:4222",
        nats.ClientCert("./certs/client-cert.pem", "./certs/client-key.pem"),
        nats.RootCAs("./certs/ca-cert.pem"),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer nc.Close()
    
    js, err := nc.JetStream()
    if err != nil {
        log.Fatal(err)
    }
    
    event := map[string]interface{}{
        "user_id":   "user123",
        "action":    "login",
        "timestamp": time.Now().Format(time.RFC3339),
    }
    
    data, _ := json.Marshal(event)
    js.Publish("eventos.usuario.login", data)
}
```

## 🔧 Configuraciones Avanzadas

### Stream con Múltiples Replicas (Solo Cluster)

```bash
# Stream replicado en el cluster
nats stream add CRITICAL_EVENTS \
  --subjects="critical.>" \
  --storage=file \
  --retention=workqueue \
  --replicas=3 \
  --max-age=30d
```

### Consumer con Dead Letter Queue

```bash
# Consumer con reintento y DLQ
nats stream add DLQ_STREAM --subjects="dlq.>"

nats consumer add EVENTOS_USUARIO procesador-con-dlq \
  --filter="eventos.usuario.>" \
  --deliver=all \
  --ack=explicit \
  --max-deliver=3 \
  --backoff=linear \
  --replay=instant
```

### Configuración de Límites

```bash
# Stream con límites específicos
nats stream add LIMITED_STREAM \
  --subjects="limited.>" \
  --storage=file \
  --retention=limits \
  --max-msgs=100000 \
  --max-bytes=1GB \
  --max-age=7d \
  --max-msg-size=1MB
```

## 📈 Casos de Uso de Producción

### 1. Event Sourcing

```bash
# Stream para eventos de dominio
nats stream add USER_EVENTS \
  --subjects="domain.user.>" \
  --storage=file \
  --retention=interest \
  --replicas=3 \
  --max-age=1y

# Eventos de ejemplo
nats pub domain.user.created '{"user_id": "123", "email": "user@example.com"}'
nats pub domain.user.email_changed '{"user_id": "123", "old_email": "user@example.com", "new_email": "new@example.com"}'
```

### 2. CQRS Pattern

```bash
# Stream para comandos
nats stream add COMMANDS \
  --subjects="cmd.>" \
  --storage=file \
  --retention=workqueue

# Stream para eventos
nats stream add EVENTS \
  --subjects="evt.>" \
  --storage=file \
  --retention=interest

# Proyecciones (consumers)
nats consumer add EVENTS user-projection --filter="evt.user.>"
nats consumer add EVENTS order-projection --filter="evt.order.>"
```

### 3. Saga Pattern

```bash
# Stream para saga orchestration
nats stream add SAGA_ORCHESTRATOR \
  --subjects="saga.>" \
  --storage=file \
  --retention=workqueue

# Ejemplo de saga de pedido
nats pub saga.order.start '{"saga_id": "saga123", "order_id": "ord456", "step": "payment"}'
nats pub saga.order.payment.success '{"saga_id": "saga123", "next_step": "inventory"}'
nats pub saga.order.inventory.success '{"saga_id": "saga123", "next_step": "shipping"}'
```

## 🎯 Best Practices

### Naming Conventions

```bash
# Subjects jerárquicos
eventos.dominio.entidad.accion
servicios.nombre_servicio.operacion
metrics.servicio.metrica
logs.nivel.servicio

# Ejemplos
eventos.usuario.login
eventos.pedido.creado
servicios.auth.validate_token
metrics.api.response_time
logs.error.payment_service
```

### Error Handling

```bash
# Stream para errores
nats stream add ERROR_HANDLING \
  --subjects="errors.>" \
  --storage=file \
  --retention=workqueue \
  --max-age=30d

# Consumer para procesamiento de errores
nats consumer add ERROR_HANDLING error-processor \
  --filter="errors.>" \
  --deliver=all \
  --ack=explicit \
  --max-deliver=5
```

### Monitoring Streams

```bash
# Stream para métricas del sistema
nats stream add SYSTEM_METRICS \
  --subjects="metrics.>" \
  --storage=memory \
  --retention=limits \
  --max-age=1h

# Publicar métricas
nats pub metrics.nats.connections "$(curl -s http://localhost:8222/varz | jq .connections)"
nats pub metrics.nats.in_msgs "$(curl -s http://localhost:8222/varz | jq .in_msgs)"
```

¡Estos ejemplos te proporcionan una base sólida para implementar patrones de mensajería robustos con NATS y JetStream! 🚀
