# Ejemplos de Cliente NATS con TLS

Este directorio contiene ejemplos de cómo conectarse al cluster NATS con TLS habilitado.

## Archivos

- `nats_client_tls.py` - Cliente Python con TLS
- `nats_client_tls.js` - Cliente Node.js con TLS
- `package.json` - Dependencias para el ejemplo de Node.js
- `requirements.txt` - Dependencias para el ejemplo de Python

## Preparación

### 1. Iniciar el cluster TLS

```bash
cd ..
./nats-cluster-tls.sh start
```

### 2. Instalar dependencias

#### Python
```bash
pip install -r requirements.txt
```

#### Node.js
```bash
npm install
```

## Ejecución

### Cliente Python
```bash
python nats_client_tls.py
```

### Cliente Node.js
```bash
node nats_client_tls.js
```

## Lo que hacen los ejemplos

1. **Conectan al cluster NATS con TLS** usando certificados cliente
2. **Crean un stream JetStream** para pruebas si no existe
3. **Publican un mensaje** de prueba
4. **Se suscriben al topic** y reciben el mensaje
5. **Muestran información del servidor** incluyendo estado TLS
6. **Cierran la conexión** apropiadamente

## Características demostradas

- ✅ **Conexión TLS segura** con verificación de certificados
- ✅ **Autenticación** con usuario y contraseña
- ✅ **JetStream** para mensajería persistente
- ✅ **Publicación/Suscripción** de mensajes
- ✅ **Manejo de errores** y limpieza de recursos
- ✅ **Información del servidor** y estado de la conexión

## Troubleshooting

### Error de certificados
```
❌ Certificados no encontrados
```
**Solución**: Ejecutar `../generate-tls-certs.sh` primero

### Error de conexión
```
❌ Error de conexión: connection refused
```
**Solución**: Verificar que el cluster esté corriendo con `../nats-cluster-tls.sh status`

### Error de autenticación
```
❌ Error: authorization violation
```
**Solución**: Verificar usuario/contraseña en el código
