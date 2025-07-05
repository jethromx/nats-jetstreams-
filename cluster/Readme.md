# NATS Cluster POC

Este proyecto contiene una configuración de cluster NATS con JetStream para alta disponibilidad.

## Estructura del Cluster

- **nats-node-1**: Puerto 4222, HTTP 8222, Cluster 6222
- **nats-node-2**: Puerto 4223, HTTP 8223, Cluster 6223  
- **nats-node-3**: Puerto 4224, HTTP 8224, Cluster 6224

## Archivos de Configuración

- `nats-node-1.conf` - Configuración del nodo 1
- `nats-node-2.conf` - Configuración del nodo 2
- `nats-node-3.conf` - Configuración del nodo 3
- `docker-compose.yml` - Definición del cluster
- `nats-cluster.sh` - Script de gestión

## Uso Rápido

```bash
# Iniciar el cluster
./nats-cluster.sh start

# Ver estado
./nats-cluster.sh status

# Ver logs de todos los nodos
./nats-cluster.sh logs

# Ver logs de un nodo específico
./nats-cluster.sh logs 1

# Detener el cluster
./nats-cluster.sh stop

# Limpiar datos
./nats-cluster.sh clean
```

## Características

- **JetStream habilitado** con persistencia en disco
- **Autenticación** con usuarios admin y service
- **Cluster de 3 nodos** para alta disponibilidad
- **Monitoreo HTTP** en cada nodo
- **Persistencia** de datos en directorios separados

## Acceso

### Conexión NATS
```bash
# Conectar a cualquier nodo
nats-cli context save local --server nats://admin:medflow2025@localhost:4222
```

### Monitoreo Web
- Node 1: http://localhost:8222
- Node 2: http://localhost:8223  
- Node 3: http://localhost:8224

## Usuarios Configurados

- **admin**: Permisos completos (publish/subscribe a todo)
- **service**: Permisos limitados a eventos (events.>)

---

## Construccion de imagen (método alternativo)
docker build -t medflow-nats:1.0 .

## Ejecutar el contenedor (modo producción)

docker run \
  --name nats-server \
  -p 4222:4222 -p 8222:8222 -p 6222:6222 \
  -v ./jetstream_data:/data/jetstream \
  medflow-nats:1.0

## Verificar JetStream:

docker exec -it nats-server nats server info

---

## 🔐 Configuración con TLS

Para usar el cluster NATS con seguridad TLS habilitada:

### Archivos TLS

- `docker-compose-tls.yml` - Definición del cluster con TLS
- `nats-node-1-tls.conf` - Configuración del nodo 1 con TLS
- `nats-node-2-tls.conf` - Configuración del nodo 2 con TLS  
- `nats-node-3-tls.conf` - Configuración del nodo 3 con TLS
- `nats-cluster-tls.sh` - Script de gestión del cluster TLS
- `generate-tls-certs.sh` - Generador de certificados TLS
- `setup-nats-client.sh` - Configurador de cliente NATS con TLS

### Uso del Cluster TLS

```bash
# Generar certificados TLS (solo la primera vez)
./generate-tls-certs.sh

# Iniciar el cluster con TLS
./nats-cluster-tls.sh start

# Ver estado del cluster
./nats-cluster-tls.sh status

# Probar conectividad TLS
./nats-cluster-tls.sh test

# Ver logs
./nats-cluster-tls.sh logs

# Detener el cluster
./nats-cluster-tls.sh stop

# Limpiar datos
./nats-cluster-tls.sh clean

# Regenerar certificados
./nats-cluster-tls.sh certs
```

### Configuración de Cliente TLS

```bash
# Configurar cliente NATS para TLS (requiere nats-cli)
./setup-nats-client.sh

# Seleccionar contexto TLS
nats context select nats-tls-admin

# Verificar conexión
nats server info

# Probar mensajería
nats pub test.message "Hello TLS World!"
nats sub test.message
```

### Conexiones TLS

- **Admin TLS**: `tls://admin:medflow2025@localhost:4222`
- **Service TLS**: `tls://service:medflow2025@localhost:4222`

### Certificados Generados

- `certs/ca-cert.pem` - Certificado de la Autoridad Certificadora
- `certs/server-cert.pem` - Certificado del servidor NATS
- `certs/client-cert.pem` - Certificado del cliente
- `certs/ca-key.pem` - Clave privada de la CA
- `certs/server-key.pem` - Clave privada del servidor
- `certs/client-key.pem` - Clave privada del cliente

### Características TLS

- **Cifrado TLS 1.2+** para todas las conexiones cliente-servidor
- **Cifrado TLS** para comunicaciones inter-cluster
- **Verificación mutua** de certificados (mTLS)
- **Certificados auto-firmados** para desarrollo/testing
- **Subject Alternative Names (SAN)** para múltiples hostnames/IPs

---

## Comparación: Sin TLS vs Con TLS

| Característica | Sin TLS | Con TLS |
|----------------|---------|---------|
| Cifrado | ❌ No | ✅ Sí (TLS 1.2+) |
| Autenticación | 🔐 Usuario/Contraseña | 🔐 Usuario/Contraseña + Certificados |
| Verificación | ❌ No | ✅ Verificación mutua (mTLS) |
| Seguridad | 🟡 Básica | 🟢 Alta |
| Complejidad | 🟢 Simple | 🟡 Moderada |
| Rendimiento | 🟢 Máximo | 🟡 Ligeramente menor |
| Uso recomendado | Desarrollo local | Producción/Desarrollo seguro |

---