#!/usr/bin/env python3
import asyncio
import json
import random
import websockets
import time

# Configurações de conexão
SERVER_URL = "ws://localhost:4000/socket/websocket"

async def send_message(websocket, event, topic, payload, ref=None):
    """Envia uma mensagem formatada para o servidor Phoenix"""
    if ref is None:
        ref = str(random.randint(1, 100000))
    
    message = {
        "event": event,
        "topic": topic,
        "payload": payload,
        "ref": ref
    }
    
    message_json = json.dumps(message)
    print(f"Enviando: {message_json}")
    await websocket.send(message_json)
    return ref

async def receive_message(websocket):
    """Recebe e processa uma mensagem do servidor"""
    response = await websocket.recv()
    print(f"Recebido: {response}")
    return json.loads(response)

async def join_channel(websocket, topic="websocket"):
    """Entra em um canal Phoenix"""
    ref = await send_message(websocket, "phx_join", topic, {})
    response = await receive_message(websocket)
    
    if response.get("event") == "phx_reply" and response.get("payload", {}).get("status") == "ok":
        print(f"Conectado ao canal {topic} com sucesso!")
        return True
    else:
        print(f"Falha ao conectar ao canal {topic}")
        return False

async def create_user(websocket, username, email, password):
    """Cria um novo usuário usando o formato simplificado"""
    payload = {
        "action": "create_user",
        "username": username,
        "email": email,
        "password": password,
        "request_id": str(random.randint(1, 100000))
    }
    
    ref = await send_message(websocket, "message", "websocket", payload)
    response = await receive_message(websocket)
    
    if response.get("event") == "phx_reply":
        status = response.get("payload", {}).get("status")
        if status == "ok":
            print("Usuário criado com sucesso!")
            return True
        else:
            reason = response.get("payload", {}).get("response", {}).get("reason", "Erro desconhecido")
            print(f"Falha ao criar usuário: {reason}")
    
    return False

async def list_users(websocket):
    """Lista todos os usuários"""
    payload = {
        "action": "list_users",
        "request_id": str(random.randint(1, 100000))
    }
    
    ref = await send_message(websocket, "message", "websocket", payload)
    response = await receive_message(websocket)
    
    if response.get("event") == "phx_reply":
        status = response.get("payload", {}).get("status")
        if status == "ok":
            users = response.get("payload", {}).get("response", {}).get("data", [])
            print(f"Usuários encontrados: {len(users)}")
            for user in users:
                print(f"  - {user.get('username')} ({user.get('email')})")
            return True
        else:
            reason = response.get("payload", {}).get("response", {}).get("reason", "Erro desconhecido")
            print(f"Falha ao listar usuários: {reason}")
    
    return False

async def main():
    """Função principal"""
    print("Conectando ao servidor WebSocket...")
    
    async with websockets.connect(SERVER_URL) as websocket:
        print("Conexão estabelecida!")
        
        # Entra no canal Phoenix
        if not await join_channel(websocket):
            return
        
        # Gera um nome de usuário único
        username = f"user_{random.randint(1000, 9999)}"
        email = f"{username}@example.com"
        
        # Cria um novo usuário
        print(f"\nCriando usuário: {username} ({email})...")
        await create_user(websocket, username, email, "senha123")
        
        # Aguarda um pouco para o servidor processar
        await asyncio.sleep(1)
        
        # Lista todos os usuários
        print("\nListando usuários...")
        await list_users(websocket)
        
        # Mantém a conexão aberta por um tempo
        print("\nMantendo conexão aberta por 5 segundos...")
        await asyncio.sleep(5)
        
        print("Teste concluído!")

if __name__ == "__main__":
    asyncio.run(main())
