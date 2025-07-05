# Guía de Instalación - NATS JetStream POC

Esta guía te ayudará a configurar y ejecutar las implementaciones NATS con TLS en tu entorno local.

## 📋 Prerrequisitos

### Software Requerido

#### Obligatorio
- **Docker**: >= 20.0
- **Docker Compose**: >= 2.0
- **Git**: Para clonar el repositorio
- **Bash**: Shell para ejecutar scripts (macOS/Linux/WSL)

#### Opcional pero Recomendado
- **NATS CLI**: Para testing y gestión
- **jq**: Para formatear JSON en comandos curl
- **OpenSSL**: Para verificar certificados (usualmente preinstalado)

### Instalación de Prerrequisitos

#### macOS (usando Homebrew)
```bash
# Docker Desktop
brew install --cask docker

# NATS CLI
brew install nats-io/nats-tools/nats

# jq para formateo JSON
brew install jq
```

#### Ubuntu/Debian
```bash
# Docker
sudo apt update
sudo apt install docker.io docker-compose

# NATS CLI
curl -sf https://binaries.nats.dev/nats-io/nats/nats@latest | sh

# jq
sudo apt install jq
```

#### Windows (usando WSL2)
```bash
# Instalar WSL2 y Ubuntu
wsl --install

# Seguir instrucciones de Ubuntu arriba
# Docker Desktop debe estar configurado para WSL2
```

## 🚀 Instalación del Proyecto

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd nats-jetstreams
```

### 2. Verificar Docker

```bash
# Verificar que Docker está corriendo
docker --version
docker-compose --version

# Test básico
docker run hello-world
```

### 3. Elegir Configuración

Tienes dos opciones principales:

#### Opción A: Desarrollo Simple (Single Node)
```bash
cd single
ls -la  # Verificar archivos
```

#### Opción B: Alta Disponibilidad (Cluster)
```bash
cd cluster
ls -la  # Verificar archivos
```

## 🔐 Configuración Single Node (Recomendado para Empezar)

### Paso 1: Verificar Certificados
```bash
cd single

# Los certificados ya deberían estar presentes
ls -la certs/
```

Si no hay certificados:
```bash
# Generar certificados (si es necesario)
./generate-certs.sh
```

### Paso 2: Iniciar el Servidor
```bash
# Iniciar servidor NATS con TLS
./nats-single.sh start

# Esperar unos segundos y verificar estado
./nats-single.sh status
```

### Paso 3: Configurar Cliente NATS (Opcional)
```bash
# Solo si tienes NATS CLI instalado
./setup-client.sh

# Seleccionar contexto y probar
nats context select nats-single-admin
nats server info
```

### Paso 4: Probar Conectividad
```bash
# Test automático
./nats-single.sh test

# Test manual con curl
curl -s http://localhost:8222/varz | jq .version
curl -s http://localhost:8222/healthz
```

## 🏗️ Configuración Cluster (Para Alta Disponibilidad)

### Paso 1: Generar Certificados TLS
```bash
cd cluster

# Generar certificados para cluster
./generate-tls-certs.sh
```

### Paso 2: Iniciar Cluster
```bash
# Opción 1: Cluster con TLS (recomendado)
./nats-cluster-tls.sh start

# Opción 2: Cluster sin TLS (solo para testing)
./nats-cluster.sh start
```

### Paso 3: Verificar Cluster
```bash
# Ver estado de todos los nodos
./nats-cluster-tls.sh status

# Test de conectividad
./nats-cluster-tls.sh test
```

### Paso 4: Configurar Cliente
```bash
# Configurar contextos NATS CLI
./setup-nats-client.sh

# Probar conexión
nats context select nats-tls-admin
nats server info
```

## 🧪 Primeras Pruebas

### Test Básico con HTTP
```bash
# Información del servidor
curl -s http://localhost:8222/varz | jq '.server_name, .version, .jetstream'

# Health check
curl http://localhost:8222/healthz

# Conexiones activas
curl -s http://localhost:8222/connz | jq '.connections | length'
```

### Test con NATS CLI (si está instalado)
```bash
# Publicar mensaje simple
nats pub test.hello "Hello NATS World!"

# Suscribirse (en otra terminal)
nats sub test.hello

# Crear stream JetStream
nats stream add DEMO \
  --subjects="demo.>" \
  --storage=file \
  --retention=workqueue

# Publicar a stream
nats pub demo.test "Message to JetStream"

# Ver streams
nats stream ls
```

### Test con Ejemplos de Código

#### Python
```bash
cd examples

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar ejemplo
python nats_single_client.py  # o nats_client_tls.py para cluster
```

#### Node.js
```bash
cd examples

# Instalar dependencias
npm install

# Ejecutar ejemplo
node nats_single_client.js    # o nats_client_tls.js para cluster
```

## 🛠️ Comandos de Gestión Útiles

### Single Node
```bash
cd single

# Gestión básica
./nats-single.sh start      # Iniciar
./nats-single.sh stop       # Detener
./nats-single.sh restart    # Reiniciar
./nats-single.sh status     # Ver estado
./nats-single.sh logs       # Ver logs

# Gestión avanzada
./nats-single.sh shell      # Acceso shell al contenedor
./nats-single.sh backup     # Backup de JetStream
./nats-single.sh clean      # Limpiar datos
./nats-single.sh info       # Información completa
```

### Cluster
```bash
cd cluster

# Sin TLS
./nats-cluster.sh start|stop|status|logs

# Con TLS
./nats-cluster-tls.sh start|stop|status|logs|test
```

## 🔍 Verificación de la Instalación

### Checklist de Verificación

#### ✅ Docker Funcionando
```bash
docker ps  # Debe mostrar contenedores NATS corriendo
```

#### ✅ Puertos Accesibles
```bash
# Single node
curl http://localhost:8222/healthz  # Debe retornar "ok"

# Cluster
curl http://localhost:8222/healthz  # Nodo 1
curl http://localhost:8223/healthz  # Nodo 2
curl http://localhost:8224/healthz  # Nodo 3
```

#### ✅ TLS Funcionando
```bash
# Verificar certificados
openssl x509 -in certs/server-cert.pem -text -noout | grep "Subject Alternative Name"

# Test de conectividad TLS (con scripts)
./nats-single.sh test      # Single
./nats-cluster-tls.sh test # Cluster
```

#### ✅ JetStream Activo
```bash
curl -s http://localhost:8222/jsz | jq '.config.enabled'  # Debe ser true
```

## 🚨 Resolución de Problemas Comunes

### Error: Puerto en Uso
```bash
# Problema: Port 4222 already in use
# Solución:
docker ps | grep nats
docker stop <container-id>

# O encontrar proceso que usa el puerto
lsof -i :4222
kill <pid>
```

### Error: Docker No Disponible
```bash
# Problema: Cannot connect to Docker daemon
# Solución en macOS:
open /Applications/Docker.app

# Solución en Linux:
sudo systemctl start docker
sudo usermod -aG docker $USER  # Reiniciar sesión después
```

### Error: Certificados TLS
```bash
# Problema: TLS handshake failed
# Solución: Regenerar certificados
cd single && ./generate-certs.sh
# o
cd cluster && ./generate-tls-certs.sh
```

### Error: Contenedor Reiniciando
```bash
# Ver logs para diagnosticar
docker logs nats-single-tls

# Revisar configuración
cat nats-server-tls.conf  # Buscar errores de sintaxis
```

## 📊 Monitoring Básico

### Endpoints de Monitoreo
```bash
# Información general del servidor
curl -s http://localhost:8222/varz | jq .

# Estadísticas de conexiones
curl -s http://localhost:8222/connz | jq .

# Estado de JetStream
curl -s http://localhost:8222/jsz | jq .

# Información de rutas (solo cluster)
curl -s http://localhost:8222/routez | jq .
```

### Logs en Tiempo Real
```bash
# Single
./nats-single.sh logs

# Cluster
./nats-cluster-tls.sh logs     # Todos los nodos
./nats-cluster-tls.sh logs 1   # Solo nodo 1
```

## 🎯 Próximos Pasos

Una vez que tengas todo funcionando:

1. **Explorar JetStream**: Crear streams y consumers
2. **Probar ejemplos**: Ejecutar códigos Python/Node.js
3. **Experimentar con permisos**: Probar diferentes usuarios
4. **Testing de carga**: Usar herramientas como `nats bench`
5. **Integración**: Conectar tus aplicaciones

## 📞 Soporte

Si encuentras problemas:

1. **Revisar logs**: Siempre empezar con los logs del contenedor
2. **Verificar configuración**: Comprobar archivos `.conf`
3. **Testing paso a paso**: Usar los scripts de test incluidos
4. **Documentación**: Consultar README específicos en cada carpeta

¡Ya tienes NATS con JetStream y TLS funcionando! 🎉
