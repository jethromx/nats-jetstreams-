#!/usr/bin/env node
/**
 * Ejemplo de cliente NATS con TLS en Node.js
 * Requiere: npm install nats
 */

const { connect, StringCodec } = require('nats');
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
            console.log('❌ Certificados no encontrados. Ejecuta primero: ./generate-tls-certs.sh');
            process.exit(1);
        }
        
        console.log('🔐 Iniciando cliente NATS con TLS...');
        
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
        
        console.log('✅ Conectado a NATS con TLS!');
        
        // String codec para mensajes
        const sc = StringCodec();
        
        // Obtener JetStream manager
        const jsm = await nc.jetstreamManager();
        const js = nc.jetstream();
        
        // Crear stream para pruebas
        try {
            await jsm.streams.add({
                name: 'TEST_STREAM',
                subjects: ['test.>'],
                retention: 'workqueue',
                max_msgs: 1000,
                storage: 'file'
            });
            console.log("✅ Stream 'TEST_STREAM' creado!");
        } catch (err) {
            if (err.message.includes('already exists')) {
                console.log("ℹ️  Stream 'TEST_STREAM' ya existe");
            } else {
                console.log(`❌ Error creando stream: ${err.message}`);
            }
        }
        
        // Suscribirse a mensajes
        const sub = js.subscribe('test.hello', {
            durable_name: 'test-consumer'
        });
        
        console.log("👂 Suscrito a 'test.hello'");
        
        // Manejar mensajes
        (async () => {
            for await (const m of sub) {
                console.log(`📥 Mensaje recibido: ${sc.decode(m.data)}`);
                console.log(`   Subject: ${m.subject}`);
                console.log(`   Headers: ${JSON.stringify(m.headers)}`);
                m.ack();
            }
        })();
        
        // Publicar un mensaje de prueba
        await js.publish('test.hello', sc.encode('Hello from TLS Node.js client!'));
        console.log("📤 Mensaje publicado a 'test.hello'");
        
        // Esperar un poco para recibir mensajes
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Información del servidor
        const status = nc.status();
        console.log('\n📊 Información del servidor:');
        console.log(`   Estado: ${status}`);
        console.log(`   TLS: ✅ Habilitado`);
        console.log(`   JetStream: ✅ Habilitado`);
        
        // Cerrar conexión
        await nc.close();
        console.log('🔌 Conexión cerrada');
        
    } catch (err) {
        console.error(`❌ Error: ${err.message}`);
        process.exit(1);
    }
}

main();
