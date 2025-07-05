#!/usr/bin/env python3
"""
Ejemplo de cliente NATS Single con TLS en Python
Requiere: pip install nats-py
"""

import asyncio
import ssl
import os
import json
from datetime import datetime
from nats.aio.client import Client as NATS


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
        
        print("✅ Conectado a NATS Single con TLS!")
        
        # Obtener JetStream context
        js = nc.jetstream()
        
        # Crear streams para diferentes tipos de mensajes
        streams_config = [
            {
                "name": "EVENTS",
                "subjects": ["events.>"],
                "description": "Stream para eventos del sistema"
            },
            {
                "name": "SERVICES",
                "subjects": ["services.>"],
                "description": "Stream para comunicación entre servicios"
            },
            {
                "name": "APPLICATIONS",
                "subjects": ["app.>"],
                "description": "Stream para aplicaciones cliente"
            }
        ]
        
        for stream_config in streams_config:
            try:
                await js.add_stream(
                    name=stream_config["name"],
                    subjects=stream_config["subjects"],
                    retention="workqueue",
                    max_msgs=10000,
                    max_age=24*60*60,  # 24 horas
                    storage="file"
                )
                print(f"✅ Stream '{stream_config['name']}' creado: {stream_config['description']}")
            except Exception as e:
                if "already exists" in str(e):
                    print(f"ℹ️  Stream '{stream_config['name']}' ya existe")
                else:
                    print(f"❌ Error creando stream {stream_config['name']}: {e}")
        
        # Función para manejar mensajes
        async def message_handler(msg):
            try:
                data = json.loads(msg.data.decode())
                print(f"📥 Mensaje recibido en {msg.subject}:")
                print(f"   Datos: {json.dumps(data, indent=2)}")
                print(f"   Timestamp: {datetime.now().isoformat()}")
                await msg.ack()
            except json.JSONDecodeError:
                print(f"📥 Mensaje de texto recibido en {msg.subject}: {msg.data.decode()}")
                await msg.ack()
        
        # Suscribirse a diferentes streams
        print("\n👂 Configurando suscripciones...")
        
        await js.subscribe("events.>", cb=message_handler, durable="events-consumer")
        print("   - Suscrito a eventos (events.>)")
        
        await js.subscribe("services.>", cb=message_handler, durable="services-consumer")
        print("   - Suscrito a servicios (services.>)")
        
        await js.subscribe("app.>", cb=message_handler, durable="app-consumer")
        print("   - Suscrito a aplicaciones (app.>)")
        
        # Publicar mensajes de ejemplo
        print("\n📤 Publicando mensajes de ejemplo...")
        
        # Evento de usuario
        user_event = {
            "event": "user.login",
            "user_id": "user123",
            "timestamp": datetime.now().isoformat(),
            "ip_address": "192.168.1.100"
        }
        await js.publish("events.user.login", json.dumps(user_event).encode())
        print("   - Evento de usuario publicado")
        
        # Mensaje entre servicios
        service_msg = {
            "service": "auth-service",
            "action": "validate_token",
            "token": "abc123xyz",
            "timestamp": datetime.now().isoformat()
        }
        await js.publish("services.auth.validate", json.dumps(service_msg).encode())
        print("   - Mensaje de servicio publicado")
        
        # Notificación de aplicación
        app_notification = {
            "type": "notification",
            "title": "Nueva funcionalidad disponible",
            "message": "Se ha agregado soporte para TLS en NATS",
            "timestamp": datetime.now().isoformat()
        }
        await js.publish("app.notifications.new", json.dumps(app_notification).encode())
        print("   - Notificación de app publicada")
        
        # Esperar para recibir mensajes
        print("\n⏳ Esperando mensajes (10 segundos)...")
        await asyncio.sleep(10)
        
        # Información del servidor
        info = await nc.server_info()
        print(f"\n📊 Información del servidor:")
        print(f"   Servidor: {info['server_name']}")
        print(f"   Versión: {info['version']}")
        print(f"   TLS: {'✅ Habilitado' if info.get('tls_required') else '❌ No requerido'}")
        print(f"   JetStream: {'✅ Habilitado' if info.get('jetstream') else '❌ Deshabilitado'}")
        
        # Mostrar estadísticas de streams
        print(f"\n📈 Estadísticas de streams:")
        for stream_name in ["EVENTS", "SERVICES", "APPLICATIONS"]:
            try:
                stream_info = await js.stream_info(stream_name)
                state = stream_info.state
                print(f"   {stream_name}:")
                print(f"     - Mensajes: {state.messages}")
                print(f"     - Bytes: {state.bytes}")
                print(f"     - Consumidores: {state.consumer_count}")
            except Exception as e:
                print(f"   {stream_name}: Error obteniendo info - {e}")
        
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
    finally:
        # Cerrar conexión
        await nc.close()
        print("\n🔌 Conexión cerrada")


if __name__ == "__main__":
    # Verificar que existen los certificados
    if not os.path.exists('./certs/ca-cert.pem'):
        print("❌ Certificados no encontrados. Ejecuta primero: ./generate-certs.sh")
        exit(1)
    
    print("🔐 Iniciando cliente NATS Single con TLS...")
    print("=" * 60)
    asyncio.run(main())
