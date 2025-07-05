# NATS Server Single con TLS

Configuración de servidor NATS individual (single node) con TLS habilitado para desarrollo y testing.

## 🚀 Inicio Rápido

```bash
# Verificar certificados (ya deberían estar generados)
ls -la certs/

# Iniciar el servidor
./nats-single.sh start

# Verificar estado
./nats-single.sh status

# Probar conectividad
./nats-single.sh test

# Ver logs
./nats-single.sh logs

# Detener servidor
./nats-single.sh stop
```

## 📁 Estructura de Archivos

```
single/
├── certs/                      # Certificados TLS
│   ├── ca-cert.pem            # Certificado CA
│   ├── ca-key.pem             # Clave privada CA
│   ├── server-cert.pem        # Certificado servidor
│   ├── server-key.pem         # Clave privada servidor
│   ├── client-cert.pem        # Certificado cliente
│   └── client-key.pem         # Clave privada cliente
├── data/                       # Datos persistentes
│   └── jetstream/             # Almacenamiento JetStream
├── logs/                       # Archivos de log
├── examples/                   # Ejemplos de cliente
│   ├── nats_single_client.py  # Cliente Python
│   ├── nats_single_client.js  # Cliente Node.js
│   ├── package.json           # Deps Node.js
│   └── requirements.txt       # Deps Python
├── docker-compose.yml          # Configuración Docker
├── nats-server-tls.conf       # Configuración NATS
├── nats-single.sh             # Script de gestión
├── setup-client.sh            # Configurador cliente CLI
└── generate-certs.sh          # Generador certificados
```

## ⚙️ Configuración

### Puertos Expuestos

- **4222**: NATS TLS (conexiones cliente)
- **8222**: HTTP Monitoring (sin TLS)
- **8080**: WebSocket TLS (opcional)

### Usuarios Configurados

| Usuario | Contraseña | Permisos |
|---------|------------|----------|
| `admin` | `medflow2025` | Acceso completo (`>`) |
| `service` | `medflow2025` | `events.>`, `services.>` |
| `client` | `medflow2025` | `app.>`, `client.>` |

### Configuración JetStream

- **Almacenamiento**: File-based persistente
- **Memoria máxima**: 4GB
- **Archivo máximo**: 20GB
- **Compresión**: Habilitada
- **Ubicación**: `./data/jetstream`

## 🔐 Configuración TLS

### Características

- ✅ **TLS 1.2+** para conexiones cliente
- ✅ **Verificación mutua** de certificados (mTLS)
- ✅ **WebSocket TLS** en puerto 8080
- ✅ **Certificados auto-firmados** para desarrollo
- ✅ **Subject Alternative Names** para múltiples hostnames

### Conexiones Disponibles

```bash
# Admin con permisos completos
tls://admin:medflow2025@localhost:4222

# Service con permisos limitados
tls://service:medflow2025@localhost:4222

# Client con permisos de aplicación
tls://client:medflow2025@localhost:4222

# WebSocket TLS
wss://admin:medflow2025@localhost:8080
```

## 🛠️ Uso del Script de Gestión

```bash
# Comandos básicos
./nats-single.sh start      # Iniciar servidor
./nats-single.sh stop       # Detener servidor
./nats-single.sh restart    # Reiniciar servidor
./nats-single.sh status     # Ver estado
./nats-single.sh logs       # Ver logs en tiempo real

# Comandos avanzados
./nats-single.sh shell      # Acceso shell al contenedor
./nats-single.sh test       # Probar conectividad TLS
./nats-single.sh info       # Información del servidor
./nats-single.sh clean      # Limpiar datos JetStream

# Backup y restore
./nats-single.sh backup     # Crear backup de JetStream
./nats-single.sh restore backup-20250704-143022  # Restaurar backup
```

## 👥 Configuración de Cliente NATS CLI

```bash
# Configurar todos los contextos
./setup-client.sh

# Usar contexto admin
nats context select nats-single-admin
nats server info

# Usar contexto service
nats context select nats-single-service
nats pub events.user.login '{"user":"john","action":"login"}'

# Usar contexto client
nats context select nats-single-client
nats pub app.notification 'Hello from app!'
```

## 📝 Ejemplos de Código

### Python

```bash
cd examples
pip install -r requirements.txt
python nats_single_client.py
```

### Node.js

```bash
cd examples
npm install
node nats_single_client.js
```

## 🔍 Monitoreo

### Endpoints HTTP

- **Server Info**: http://localhost:8222/varz
- **Health Check**: http://localhost:8222/healthz
- **Connections**: http://localhost:8222/connz
- **JetStream**: http://localhost:8222/jsz

### Comandos de Monitoreo

```bash
# Ver información del servidor
curl -s http://localhost:8222/varz | jq .

# Ver health check
curl -s http://localhost:8222/healthz

# Ver conexiones activas
curl -s http://localhost:8222/connz | jq .

# Ver información de JetStream
curl -s http://localhost:8222/jsz | jq .
```

## 🧪 Testing

### Test de Conectividad TLS

```bash
# Test automático
./nats-single.sh test

# Test manual con NATS CLI
nats context select nats-single-admin
nats server ping
nats server check stream
nats server check jetstream
```

### Test de Mensajería

```bash
# Publicar mensaje
nats pub test.hello "Hello TLS World!"

# Suscribirse a mensajes
nats sub test.hello

# Crear stream y consumer
nats stream add TEST --subjects="test.>" --storage=file
nats consumer add TEST test-consumer --pull
```

## 🚨 Troubleshooting

### Error: Certificados no encontrados

```bash
❌ Certificados TLS no encontrados
```

**Solución**: Generar certificados
```bash
./generate-certs.sh
```

### Error: Puerto en uso

```bash
❌ Port 4222 already in use
```

**Solución**: Detener otros servicios NATS
```bash
docker ps | grep nats
docker stop <container_id>
```

### Error: Conexión rechazada

```bash
❌ Error de conexión: connection refused
```

**Solución**: Verificar que el servidor esté corriendo
```bash
./nats-single.sh status
./nats-single.sh start
```

### Error: Verificación TLS

```bash
❌ TLS handshake failed
```

**Solución**: Verificar certificados y configuración
```bash
openssl x509 -in certs/server-cert.pem -text -noout
./nats-single.sh test
```

## 🔧 Configuración Avanzada

### Personalizar Configuración

Editar `nats-server-tls.conf` para:
- Cambiar límites de memoria/disco
- Agregar usuarios adicionales
- Modificar configuración TLS
- Configurar logging

### Variables de Entorno

```bash
# En docker-compose.yml
environment:
  - NATS_SERVER_NAME=mi-servidor-custom
  - NATS_LOG_LEVEL=debug
```

### Certificados Personalizados

Reemplazar certificados en `./certs/` con:
- Certificados emitidos por CA válida para producción
- Certificados con dominios específicos
- Certificados con configuración personalizada

## 📚 Recursos Adicionales

- [Documentación NATS](https://docs.nats.io/)
- [NATS JetStream](https://docs.nats.io/jetstream)
- [NATS Security](https://docs.nats.io/running-a-nats-service/configuration/securing_nats)
- [NATS TLS](https://docs.nats.io/running-a-nats-service/configuration/securing_nats/tls)
