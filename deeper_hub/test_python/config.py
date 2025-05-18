"""
Configurações do cliente DeeperHub.
"""
import os
from typing import Dict, Any

# Configurações padrão
DEFAULT_CONFIG: Dict[str, Any] = {
    "host": "localhost",
    "port": 4000,
    "use_ssl": False,
    "ssl_verify": True,
    "reconnect_attempts": 3,
    "reconnect_delay": 5,  # segundos
    "request_timeout": 30,  # segundos
    "rate_limit": {
        "requests_per_minute": 60,
        "burst_limit": 10
    },
    "logging": {
        "level": "INFO",
        "file": "logs/deeper_hub_client.log",
        "max_size": 10 * 1024 * 1024,  # 10MB
        "backup_count": 5
    },
    "test": {
        "timeout": 30,  # segundos
        "retry_attempts": 3,
        "parallel_tests": False
    },
    "security": {
        "allowed_origins": ["http://localhost:4000", "http://127.0.0.1:4000"],
        "websocket_protocol": "deeper-hub-protocol",
        "user_agent": "DeeperHubPythonClient/1.0.0"
    }
}

# Versão do cliente
VERSION = "1.0.0"

# Constantes de autenticação
AUTH_CONSTANTS = {
    "TOKEN_EXPIRY": 3600,  # 1 hora
    "REFRESH_TOKEN_EXPIRY": 604800,  # 7 dias
    "PASSWORD_MIN_LENGTH": 8,
    "PASSWORD_MAX_LENGTH": 128
}

# Constantes de mensagens
MESSAGE_CONSTANTS = {
    "MAX_MESSAGE_LENGTH": 4096,
    "MAX_CHANNEL_NAME_LENGTH": 64,
    "MAX_CHANNEL_DESCRIPTION_LENGTH": 256
}

# Constantes de usuário
USER_CONSTANTS = {
    "MIN_USERNAME_LENGTH": 3,
    "MAX_USERNAME_LENGTH": 32,
    "EMAIL_MAX_LENGTH": 254
}

def get_config() -> Dict[str, Any]:
    """
    Retorna a configuração atual, mesclando com variáveis de ambiente se disponíveis.
    """
    config = DEFAULT_CONFIG.copy()
    
    # Sobrescreve com variáveis de ambiente se existirem
    if os.getenv("DEEPER_HUB_HOST"):
        config["host"] = os.getenv("DEEPER_HUB_HOST")
    if os.getenv("DEEPER_HUB_PORT"):
        config["port"] = int(os.getenv("DEEPER_HUB_PORT"))
    if os.getenv("DEEPER_HUB_USE_SSL"):
        config["use_ssl"] = os.getenv("DEEPER_HUB_USE_SSL").lower() == "true"
    if os.getenv("DEEPER_HUB_SSL_VERIFY"):
        config["ssl_verify"] = os.getenv("DEEPER_HUB_SSL_VERIFY").lower() == "true"
    
    return config 