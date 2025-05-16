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
    ref = await send_message(websocket, "phx_join", topic, None)
    response = await receive_message(websocket)
    
    if response.get("event") == "phx_reply" and response.get("payload", {}).get("status") == "ok":
        print(f"Conectado ao canal {topic} com sucesso!")
        return True
    else:
        print(f"Falha ao conectar ao canal {topic}")
        return False

async def create_user(websocket):
    """Cria um novo usuário usando o formato correto da mensagem Phoenix"""
    # Gera um nome de usuário único
    username = f"user_{random.randint(1000, 9999)}"
    email = f"{username}@example.com"
    
    # Cria os dados do usuário
    user_data = {
        "username": username,
        "email": email,
        "password": "senha123"
    }
    
    # Cria a operação de banco de dados no formato esperado
    db_operation = {
        "operation": "create",
        "schema": "user",
        "id": "",
        "data": json.dumps(user_data),  # Serializa os dados como string JSON
        "request_id": str(random.randint(1, 100000)),
        "timestamp": int(time.time())
    }
    
    # Cria o payload da mensagem
    payload = {
        "database_operation": db_operation
    }
    
    # Envia a mensagem
    print(f"\nCriando usuário: {username} ({email})...")
    ref = await send_message(websocket, "message", "websocket", payload)
    response = await receive_message(websocket)
    
    return response

async def list_users(websocket):
    """Lista todos os usuários"""
    # Cria a operação de banco de dados no formato esperado
    db_operation = {
        "operation": "list",
        "schema": "user",
        "id": "",
        "data": "null",  # Valor nulo como string
        "request_id": str(random.randint(1, 100000)),
        "timestamp": int(time.time())
    }
    
    # Cria o payload da mensagem
    payload = {
        "database_operation": db_operation
    }
    
    # Envia a mensagem
    print("\nListando usuários...")
    ref = await send_message(websocket, "message", "websocket", payload)
    response = await receive_message(websocket)
    
    return response

async def main():
    """Função principal"""
    print("Conectando ao servidor WebSocket...")
    
    async with websockets.connect(SERVER_URL) as websocket:
        print("Conexão estabelecida!")
        
        # Entra no canal Phoenix
        if not await join_channel(websocket):
            return
        
        # Cria um novo usuário
        create_response = await create_user(websocket)
        print(f"Resposta da criação: {json.dumps(create_response, indent=2)}")
        
        # Aguarda um pouco para o servidor processar
        await asyncio.sleep(1)
        
        # Lista todos os usuários
        list_response = await list_users(websocket)
        print(f"Resposta da listagem: {json.dumps(list_response, indent=2)}")
        
        # Mantém a conexão aberta por um tempo
        print("\nMantendo conexão aberta por 5 segundos...")
        await asyncio.sleep(5)
        
        print("Teste concluído!")

if __name__ == "__main__":
    asyncio.run(main())
