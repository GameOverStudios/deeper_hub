"""
Testes para as novas funcionalidades do cliente DeeperHub.
"""
import asyncio
import pytest
import time
from typing import Dict, Any
from ..modules.validator import Validator
from ..modules.rate_limiter import RateLimiter
from ..modules.reconnection import ReconnectionManager
from ..modules.logger import DeeperHubLogger

# Fixtures
@pytest.fixture
def validator():
    return Validator()

@pytest.fixture
def rate_limiter():
    return RateLimiter()

@pytest.fixture
def logger():
    return DeeperHubLogger()

# Testes de Validação
class TestValidator:
    def test_validate_username(self, validator):
        # Testes válidos
        assert validator.validate_username("user123")[0] is True
        assert validator.validate_username("user_name")[0] is True
        assert validator.validate_username("user-name")[0] is True
        
        # Testes inválidos
        assert validator.validate_username("")[0] is False
        assert validator.validate_username("ab")[0] is False  # Muito curto
        assert validator.validate_username("a" * 33)[0] is False  # Muito longo
        assert validator.validate_username("user@123")[0] is False  # Caracteres inválidos
        
    def test_validate_email(self, validator):
        # Testes válidos
        assert validator.validate_email("user@example.com")[0] is True
        assert validator.validate_email("user.name@domain.co.uk")[0] is True
        
        # Testes inválidos
        assert validator.validate_email("")[0] is False
        assert validator.validate_email("invalid-email")[0] is False
        assert validator.validate_email("@domain.com")[0] is False
        assert validator.validate_email("user@")[0] is False
        
    def test_validate_password(self, validator):
        # Testes válidos
        assert validator.validate_password("Password123!")[0] is True
        assert validator.validate_password("Complex@Pass1")[0] is True
        
        # Testes inválidos
        assert validator.validate_password("")[0] is False
        assert validator.validate_password("short")[0] is False
        assert validator.validate_password("no-upper-123!")[0] is False
        assert validator.validate_password("NO-LOWER-123!")[0] is False
        assert validator.validate_password("NoNumbers!")[0] is False
        assert validator.validate_password("NoSpecial123")[0] is False

# Testes de Rate Limiting
class TestRateLimiter:
    def test_can_make_request(self, rate_limiter):
        # Deve permitir requisições dentro do limite
        for _ in range(60):
            assert rate_limiter.can_make_request() is True
            
        # Deve bloquear após exceder o limite
        assert rate_limiter.can_make_request() is False
        
    def test_wait_if_needed(self, rate_limiter):
        # Deve esperar quando necessário
        start_time = time.time()
        rate_limiter.wait_if_needed()
        end_time = time.time()
        
        # Não deve esperar se não houver limite
        assert end_time - start_time < 0.1
        
    def test_get_remaining_requests(self, rate_limiter):
        # Deve retornar o número correto de requisições restantes
        assert rate_limiter.get_remaining_requests() == 60
        
        # Deve diminuir após fazer requisições
        for _ in range(10):
            rate_limiter.can_make_request()
        assert rate_limiter.get_remaining_requests() == 50

# Testes de Reconexão
class TestReconnectionManager:
    @pytest.mark.asyncio
    async def test_handle_disconnect(self, logger):
        connected = False
        
        async def connect():
            nonlocal connected
            connected = True
            
        manager = ReconnectionManager(connect, logger)
        
        # Simula desconexão
        await manager.handle_disconnect()
        
        assert connected is True
        assert manager.attempts == 0
        assert manager.is_reconnecting is False
        
    @pytest.mark.asyncio
    async def test_reconnection_attempts(self, logger):
        attempts = 0
        
        async def connect():
            nonlocal attempts
            attempts += 1
            if attempts < 3:
                raise Exception("Connection failed")
                
        manager = ReconnectionManager(connect, logger)
        manager.max_attempts = 3
        
        # Simula desconexão
        await manager.handle_disconnect()
        
        assert attempts == 3
        assert manager.attempts == 2  # 2 tentativas falhas + 1 sucesso

# Testes de Logger
class TestLogger:
    def test_log_levels(self, logger):
        # Testa diferentes níveis de log
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.critical("Critical message")
        
    def test_websocket_event(self, logger):
        # Testa log de evento WebSocket
        event_data = {"type": "message", "content": "test"}
        logger.websocket_event("test_event", event_data)
        
    def test_api_request_response(self, logger):
        # Testa log de requisição e resposta API
        logger.api_request("GET", "/users", {"page": 1})
        logger.api_response("GET", "/users", 200, {"data": []})

# Testes de Integração
class TestIntegration:
    @pytest.mark.asyncio
    async def test_full_flow(self, validator, rate_limiter, logger):
        # Testa fluxo completo com todas as funcionalidades
        
        # Validação
        username_valid, _ = validator.validate_username("testuser")
        assert username_valid is True
        
        # Rate limiting
        assert rate_limiter.can_make_request() is True
        
        # Logger
        logger.info("Test message", {"test": True})
        
        # Reconexão
        connected = False
        async def connect():
            nonlocal connected
            connected = True
            
        manager = ReconnectionManager(connect, logger)
        await manager.handle_disconnect()
        assert connected is True 