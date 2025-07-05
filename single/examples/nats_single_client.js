#!/usr/bin/env node
/**
 * Ejemplo de cliente NATS Single con TLS en Node.js
 * Requiere: npm install nats
 */

const { connect, StringCodec, JSONCodec } = require('nats');
const fs = require('fs');
const path = require('path');

async function main() {
    try {
        // Verificar que existen los certificados
        const certsDir = path.join(__dirname, '..', 'certs');
        const caCert = path.join(certsDir, 'ca-cert.pem');
        const clientCert = path.join(certsDir, 'client-cert.pem');
        const clientKey = path.join(certsDir, 'client-key.pem');
        
        if (!fs.existsSync(caCert)) {
            console.log('❌ Certificados no encontrados. Ejecuta primero: ./generate-certs.sh');
            process.exit(1);
        }
        
        console.log('🔐 Iniciando cliente NATS Single con TLS...');
        console.log('='.repeat(60));
        
        // Configuración TLS
        const tlsOptions = {
            ca: [fs.readFileSync(caCert)],
            cert: fs.readFileSync(clientCert),
            key: fs.readFileSync(clientKey),
            servername: 'localhost'
        };
        
        // Conectar a NATS con TLS
        const nc = await connect({
            servers: ['tls://localhost:4222'],
            user: 'admin',
            pass: 'medflow2025',
            tls: tlsOptions
        });
        
        console.log('✅ Conectado a NATS Single con TLS!');
        
        // Codecs para mensajes
        const sc = StringCodec();
        const jc = JSONCodec();
        
        // Obtener JetStream manager y context
        const jsm = await nc.jetstreamManager();
        const js = nc.jetstream();
        
        // Configuración de streams
        const streamsConfig = [
            {
                name: 'EVENTS',
                subjects: ['events.>'],
                description: 'Stream para eventos del sistema'
            },
            {
                name: 'SERVICES',
                subjects: ['services.>'],
                description: 'Stream para comunicación entre servicios'
            },
            {
                name: 'APPLICATIONS',
                subjects: ['app.>'],
                description: 'Stream para aplicaciones cliente'
            }
        ];
        
        // Crear streams
        for (const streamConfig of streamsConfig) {
            try {
                await jsm.streams.add({
                    name: streamConfig.name,
                    subjects: streamConfig.subjects,
                    retention: 'workqueue',
                    max_msgs: 10000,
                    max_age: 24 * 60 * 60 * 1000000000, // 24 horas en nanosegundos
                    storage: 'file'
                });
                console.log(`✅ Stream '${streamConfig.name}' creado: ${streamConfig.description}`);
            } catch (err) {
                if (err.message.includes('already exists')) {
                    console.log(`ℹ️  Stream '${streamConfig.name}' ya existe`);
                } else {
                    console.log(`❌ Error creando stream ${streamConfig.name}: ${err.message}`);
                }
            }
        }
        
        // Configurar suscripciones
        console.log('\n👂 Configurando suscripciones...');
        
        const subscriptions = [
            { subject: 'events.>', durable: 'events-consumer', description: 'eventos' },
            { subject: 'services.>', durable: 'services-consumer', description: 'servicios' },
            { subject: 'app.>', durable: 'app-consumer', description: 'aplicaciones' }
        ];
        
        // Crear suscripciones
        for (const subConfig of subscriptions) {
            const sub = js.subscribe(subConfig.subject, {
                durable_name: subConfig.durable
            });
            
            console.log(`   - Suscrito a ${subConfig.description} (${subConfig.subject})`);
            
            // Manejar mensajes
            (async () => {
                for await (const m of sub) {
                    try {
                        const data = jc.decode(m.data);
                        console.log(`📥 Mensaje JSON recibido en ${m.subject}:`);
                        console.log(`   Datos: ${JSON.stringify(data, null, 2)}`);
                        console.log(`   Timestamp: ${new Date().toISOString()}`);
                    } catch (err) {
                        console.log(`📥 Mensaje de texto recibido en ${m.subject}: ${sc.decode(m.data)}`);
                    }
                    m.ack();
                }
            })();
        }
        
        // Publicar mensajes de ejemplo
        console.log('\n📤 Publicando mensajes de ejemplo...');
        
        // Evento de usuario
        const userEvent = {
            event: 'user.login',
            user_id: 'user123',
            timestamp: new Date().toISOString(),
            ip_address: '192.168.1.100'
        };
        await js.publish('events.user.login', jc.encode(userEvent));
        console.log('   - Evento de usuario publicado');
        
        // Mensaje entre servicios
        const serviceMsg = {
            service: 'auth-service',
            action: 'validate_token',
            token: 'abc123xyz',
            timestamp: new Date().toISOString()
        };
        await js.publish('services.auth.validate', jc.encode(serviceMsg));
        console.log('   - Mensaje de servicio publicado');
        
        // Notificación de aplicación
        const appNotification = {
            type: 'notification',
            title: 'Nueva funcionalidad disponible',
            message: 'Se ha agregado soporte para TLS en NATS',
            timestamp: new Date().toISOString()
        };
        await js.publish('app.notifications.new', jc.encode(appNotification));
        console.log('   - Notificación de app publicada');
        
        // Esperar para recibir mensajes
        console.log('\n⏳ Esperando mensajes (10 segundos)...');
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        // Información del servidor
        const status = nc.status();
        console.log('\n📊 Información del servidor:');
        console.log(`   Estado: ${status}`);
        console.log(`   TLS: ✅ Habilitado`);
        console.log(`   JetStream: ✅ Habilitado`);
        
        // Mostrar estadísticas de streams
        console.log('\n📈 Estadísticas de streams:');
        for (const streamName of ['EVENTS', 'SERVICES', 'APPLICATIONS']) {
            try {
                const streamInfo = await jsm.streams.info(streamName);
                console.log(`   ${streamName}:`);
                console.log(`     - Mensajes: ${streamInfo.state.messages}`);
                console.log(`     - Bytes: ${streamInfo.state.bytes}`);
                console.log(`     - Consumidores: ${streamInfo.state.consumer_count}`);
            } catch (err) {
                console.log(`   ${streamName}: Error obteniendo info - ${err.message}`);
            }
        }
        
        // Cerrar conexión
        await nc.close();
        console.log('\n🔌 Conexión cerrada');
        
    } catch (err) {
        console.error(`❌ Error: ${err.message}`);
        process.exit(1);
    }
}

main();
