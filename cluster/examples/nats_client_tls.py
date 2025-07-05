#!/usr/bin/env python3
"""
Ejemplo de cliente NATS con TLS en Python
Requiere: pip install nats-py
"""

import asyncio
import ssl
import os
from nats.aio.client import Client as NATS
from nats.js import JetStreamContext


async def main():
    # Configuración TLS
    tls_context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
    tls_context.load_verify_locations('./certs/ca-cert.pem')
    tls_context.load_cert_chain('./certs/client-cert.pem', './certs/client-key.pem')
    
    # Crear cliente NATS
    nc = NATS()
    
    try:
        # Conectar con TLS
        await nc.connect(
            servers=["tls://localhost:4222"],
            user="admin",
            password="medflow2025",
            tls=tls_context,
            tls_hostname="localhost"
        )
        
        print("✅ Conectado a NATS con TLS!")
        
        # Obtener JetStream context
        js = nc.jetstream()
        
        # Crear un stream para pruebas
        try:
            await js.add_stream(
                name="TEST_STREAM",
                subjects=["test.>"],
                retention="workqueue",
                max_msgs=1000,
                storage="file"
            )
            print("✅ Stream 'TEST_STREAM' creado!")
        except Exception as e:
            if "already exists" in str(e):
                print("ℹ️  Stream 'TEST_STREAM' ya existe")
            else:
                print(f"❌ Error creando stream: {e}")
        
        # Publicar mensaje
        await js.publish("test.hello", b"Hello from TLS client!")
        print("📤 Mensaje publicado a 'test.hello'")
        
        # Suscribirse y recibir mensajes
        async def message_handler(msg):
            print(f"📥 Mensaje recibido: {msg.data.decode()}")
            print(f"   Subject: {msg.subject}")
            print(f"   Headers: {msg.headers}")
            await msg.ack()
        
        # Crear consumer y suscripción
        await js.subscribe("test.hello", cb=message_handler, durable="test-consumer")
        print("👂 Suscrito a 'test.hello'")
        
        # Esperar un poco para recibir mensajes
        await asyncio.sleep(2)
        
        # Información del servidor
        info = await nc.server_info()
        print(f"\n📊 Información del servidor:")
        print(f"   Servidor: {info['server_name']}")
        print(f"   Versión: {info['version']}")
        print(f"   TLS: {'✅ Habilitado' if info.get('tls_required') else '❌ No requerido'}")
        print(f"   JetStream: {'✅ Habilitado' if info.get('jetstream') else '❌ Deshabilitado'}")
        
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
    finally:
        # Cerrar conexión
        await nc.close()
        print("🔌 Conexión cerrada")


if __name__ == "__main__":
    # Verificar que existen los certificados
    if not os.path.exists('./certs/ca-cert.pem'):
        print("❌ Certificados no encontrados. Ejecuta primero: ./generate-tls-certs.sh")
        exit(1)
    
    print("🔐 Iniciando cliente NATS con TLS...")
    asyncio.run(main())
