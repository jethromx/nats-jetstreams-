# NATS JetStream POC - Configuraciones con TLS

Este proyecto contiene implementaciones completas de NATS Server con JetStream y TLS para diferentes escenarios de uso.

## 🎯 Objetivos del Proyecto

- **Demostrar configuraciones NATS** tanto cluster como single node
- **Implementar seguridad TLS** con certificados auto-firmados
- **Configurar JetStream** para mensajería persistente
- **Proporcionar ejemplos** de clientes en múltiples lenguajes
- **Crear herramientas de gestión** para facilitar el despliegue

## 📁 Estructura del Proyecto

```
nats-jetstreams/
├── cluster/                    # Configuración Cluster (3 nodos)
│   ├── certs/                 # Certificados TLS cluster
│   ├── examples/              # Ejemplos cliente cluster
│   ├── jetstream_data/        # Datos persistentes cluster
│   ├── logs/                  # Logs cluster
│   ├── docker-compose.yml     # Cluster sin TLS
│   ├── docker-compose-tls.yml # Cluster con TLS
│   ├── nats-cluster.sh        # Gestión cluster sin TLS
│   ├── nats-cluster-tls.sh    # Gestión cluster con TLS
│   ├── generate-tls-certs.sh  # Generador certificados cluster
│   └── README.md              # Documentación cluster
├── single/                     # Configuración Single Node
│   ├── certs/                 # Certificados TLS single
│   ├── data/                  # Datos persistentes single
│   ├── examples/              # Ejemplos cliente single
│   ├── logs/                  # Logs single
│   ├── docker-compose.yml     # Single node con TLS
│   ├── nats-server-tls.conf   # Configuración NATS single
│   ├── nats-single.sh         # Gestión single node
│   ├── setup-client.sh        # Configurador cliente
│   └── README.md              # Documentación single
└── README.md                  # Este archivo
```

## 🚀 Configuraciones Disponibles

### 1. Cluster NATS (Alta Disponibilidad)

**Ubicación**: `./cluster/`

Un cluster de 3 nodos NATS con JetStream para alta disponibilidad y tolerancia a fallos.

#### Características Cluster
- ✅ **3 nodos NATS** con replicación automática
- ✅ **JetStream distribuido** con persistencia
- ✅ **TLS opcional** (sin TLS y con TLS)
- ✅ **Load balancing** automático
- ✅ **Tolerancia a fallos** (1-2 nodos pueden fallar)
- ✅ **Monitoreo independiente** por nodo

#### Configuraciones Cluster
- **Sin TLS**: Desarrollo rápido y testing local
- **Con TLS**: Desarrollo seguro y pre-producción

#### Uso Rápido Cluster
```bash
cd cluster

# Cluster sin TLS
./nats-cluster.sh start
./nats-cluster.sh status

# Cluster con TLS
./nats-cluster-tls.sh start
./nats-cluster-tls.sh status
```

### 2. Single Node NATS (Desarrollo)

**Ubicación**: `./single/`

Un servidor NATS individual con TLS para desarrollo y testing.

#### Características Single
- ✅ **Nodo único** con configuración simplificada
- ✅ **JetStream persistente** con almacenamiento local
- ✅ **TLS habilitado** por defecto
- ✅ **WebSocket TLS** para aplicaciones web
- ✅ **Backup/Restore** de datos JetStream
- ✅ **Gestión completa** con scripts automatizados

#### Uso Rápido Single
```bash
cd single
./nats-single.sh start
./nats-single.sh status
./nats-single.sh test
```

## 🔐 Seguridad TLS

Ambas configuraciones incluyen implementaciones completas de TLS:

### Certificados Incluidos
- **CA Certificate**: Autoridad certificadora auto-firmada
- **Server Certificate**: Certificado del servidor NATS
- **Client Certificate**: Certificado para clientes

### Características de Seguridad
- 🔒 **Cifrado TLS 1.2+** para todas las conexiones
- 🔒 **Verificación mutua** de certificados (mTLS)
- 🔒 **Subject Alternative Names** para múltiples hosts
- 🔒 **Autenticación** usuario/contraseña + certificados

## 👥 Usuarios Configurados

Ambas configuraciones incluyen usuarios predefinidos:

| Usuario | Contraseña | Permisos | Uso |
|---------|------------|----------|-----|
| `admin` | `medflow2025` | Completo (`>`) | Administración |
| `service` | `medflow2025` | `events.>`, `services.>` | Microservicios |
| `client` | `medflow2025` | `app.>`, `client.>` | Aplicaciones |

## 🛠️ Tecnologías Utilizadas

- **NATS Server 2.10**: Servidor de mensajería
- **JetStream**: Sistema de persistencia
- **Docker & Docker Compose**: Containerización
- **OpenSSL**: Generación de certificados TLS
- **Bash Scripts**: Automatización y gestión

## 📊 Comparación: Cluster vs Single

| Característica | Cluster | Single |
|----------------|---------|--------|
| **Nodos** | 3 nodos | 1 nodo |
| **Alta Disponibilidad** | ✅ Sí | ❌ No |
| **Tolerancia a Fallos** | ✅ Sí (1-2 nodos) | ❌ No |
| **Complejidad** | 🟡 Moderada | 🟢 Simple |
| **Recursos** | 🟡 Altos | 🟢 Bajos |
| **TLS** | ✅ Opcional/Obligatorio | ✅ Obligatorio |
| **WebSocket** | ❌ No | ✅ Sí |
| **Backup/Restore** | 🟡 Manual | ✅ Automatizado |
| **Uso Recomendado** | Producción/Pre-prod | Desarrollo/Testing |

## 🎯 Casos de Uso

### Cluster NATS
- **Producción**: Alta disponibilidad crítica
- **Pre-producción**: Testing de failover
- **Desarrollo distribuido**: Múltiples equipos
- **Load testing**: Pruebas de carga

### Single NATS
- **Desarrollo local**: Prototipado rápido
- **Testing unitario**: Pruebas de integración
- **Demos**: Presentaciones y POCs
- **Aprendizaje**: Experimentación con NATS

## 🚀 Inicio Rápido

### Opción 1: Cluster para Alta Disponibilidad

```bash
# Clonar el proyecto
git clone <repository-url>
cd nats-jetstreams/cluster

# Iniciar cluster con TLS
./generate-tls-certs.sh
./nats-cluster-tls.sh start

# Verificar estado
./nats-cluster-tls.sh status

# Configurar cliente
./setup-nats-client.sh
nats context select nats-tls-admin
nats server info
```

### Opción 2: Single Node para Desarrollo

```bash
# Clonar el proyecto
git clone <repository-url>
cd nats-jetstreams/single

# Iniciar servidor
./nats-single.sh start

# Verificar estado
./nats-single.sh status

# Configurar cliente
./setup-client.sh
nats context select nats-single-admin
nats server info
```

## 📝 Ejemplos de Cliente

Ambas configuraciones incluyen ejemplos completos:

### Python
```bash
cd examples
pip install -r requirements.txt
python nats_client_tls.py  # o nats_single_client.py
```

### Node.js
```bash
cd examples
npm install
node nats_client_tls.js    # o nats_single_client.js
```

### NATS CLI
```bash
# Publicar mensaje
nats pub test.hello "Hello NATS World!"

# Suscribirse
nats sub test.hello

# JetStream
nats stream add DEMO --subjects="demo.>" --storage=file
nats consumer add DEMO demo-consumer
```

## 🔍 Monitoreo

### Endpoints Disponibles

#### Cluster
- **Node 1**: http://localhost:8222
- **Node 2**: http://localhost:8223
- **Node 3**: http://localhost:8224

#### Single
- **Server**: http://localhost:8222
- **Health**: http://localhost:8222/healthz

### Información del Servidor
```bash
# Información general
curl -s http://localhost:8222/varz | jq .

# Conexiones activas
curl -s http://localhost:8222/connz | jq .

# Estado JetStream
curl -s http://localhost:8222/jsz | jq .
```

## 🧪 Testing y Validación

### Tests Automáticos
```bash
# Cluster
cd cluster
./nats-cluster-tls.sh test

# Single
cd single
./nats-single.sh test
```

### Tests Manuales
```bash
# Conectividad TLS
nats server ping

# JetStream
nats server check jetstream

# Streams
nats stream ls

# Consumers
nats consumer ls <stream-name>
```

## 🚨 Troubleshooting

### Problemas Comunes

#### Puertos en Uso
```bash
# Verificar puertos ocupados
netstat -an | grep 4222
lsof -i :4222

# Detener servicios
docker ps | grep nats
docker stop <container-id>
```

#### Certificados TLS
```bash
# Verificar certificados
openssl x509 -in certs/server-cert.pem -text -noout

# Regenerar certificados
./generate-certs.sh  # o ./generate-tls-certs.sh
```

#### Conexión Rechazada
```bash
# Verificar estado de contenedores
docker ps
docker logs <container-name>

# Reiniciar servicios
./nats-single.sh restart
# o
./nats-cluster-tls.sh restart
```

## 🔧 Configuración Avanzada

### Personalización de Usuarios
Editar archivos `.conf` para:
- Agregar usuarios adicionales
- Modificar permisos
- Configurar subjects específicos

### Ajuste de JetStream
```bash
# Memoria y almacenamiento
jetstream {
    max_mem: 8G      # Aumentar memoria
    max_file: 50G    # Aumentar almacenamiento
}
```

### Certificados de Producción
Reemplazar certificados auto-firmados con:
- Certificados emitidos por CA válida
- Let's Encrypt para dominios públicos
- Certificados corporativos

## 📚 Recursos Adicionales

### Documentación NATS
- [NATS.io Oficial](https://nats.io/)
- [Documentación NATS](https://docs.nats.io/)
- [JetStream Guide](https://docs.nats.io/jetstream)
- [NATS Security](https://docs.nats.io/running-a-nats-service/configuration/securing_nats)

### Herramientas
- [NATS CLI](https://github.com/nats-io/natscli)
- [NATS Docker](https://hub.docker.com/_/nats)
- [Clients Libraries](https://nats.io/download/)

### Comunidad
- [NATS Slack](https://natsio.slack.com)
- [GitHub NATS](https://github.com/nats-io)
- [NATS YouTube](https://www.youtube.com/c/Natsio)

## 🤝 Contribución

Este POC está diseñado para ser extensible. Áreas de mejora:

- **Nuevos lenguajes**: Agregar ejemplos en Go, Rust, etc.
- **Configuraciones**: Nuevas topologías de cluster
- **Monitoreo**: Integración con Prometheus/Grafana
- **CI/CD**: Pipelines de testing automático
- **Helm Charts**: Despliegue en Kubernetes

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

**Nota**: Este POC utiliza certificados auto-firmados apropiados para desarrollo y testing. Para uso en producción, utilizar certificados emitidos por una CA válida.
