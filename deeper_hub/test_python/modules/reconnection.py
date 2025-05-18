"""
Sistema de reconexão automática para o cliente WebSocket.
"""
import asyncio
import time
from typing import Optional, Callable, Any
from ..config import get_config
from .logger import DeeperHubLogger

class ReconnectionManager:
    """
    Gerencia reconexões automáticas do WebSocket com backoff exponencial.
    """
    
    def __init__(self, connect_callback: Callable[[], Any], logger: Optional[DeeperHubLogger] = None):
        """
        Inicializa o gerenciador de reconexão.
        
        Args:
            connect_callback: Função assíncrona para estabelecer a conexão
            logger: Instância do logger (opcional)
        """
        self.config = get_config()
        self.connect_callback = connect_callback
        self.logger = logger or DeeperHubLogger()
        
        self.attempts = 0
        self.max_attempts = self.config["reconnect_attempts"]
        self.base_delay = self.config["reconnect_delay"]
        self.is_reconnecting = False
        self.last_attempt_time: Optional[float] = None
        
    async def handle_disconnect(self) -> None:
        """
        Lida com a desconexão do WebSocket.
        """
        if self.is_reconnecting:
            return
            
        self.is_reconnecting = True
        self.attempts = 0
        
        while self.attempts < self.max_attempts:
            try:
                await self._attempt_reconnection()
                self.is_reconnecting = False
                return
            except Exception as e:
                self.logger.error(f"Falha na reconexão (tentativa {self.attempts + 1}/{self.max_attempts})", 
                                {"error": str(e)})
                self.attempts += 1
                
                if self.attempts < self.max_attempts:
                    delay = self._calculate_delay()
                    self.logger.info(f"Aguardando {delay} segundos antes da próxima tentativa")
                    await asyncio.sleep(delay)
                    
        self.logger.error("Número máximo de tentativas de reconexão atingido")
        self.is_reconnecting = False
        
    async def _attempt_reconnection(self) -> None:
        """
        Tenta reconectar ao servidor.
        """
        self.last_attempt_time = time.time()
        self.logger.info(f"Tentando reconectar (tentativa {self.attempts + 1}/{self.max_attempts})")
        
        await self.connect_callback()
        
        self.logger.info("Reconexão bem-sucedida")
        self.attempts = 0
        
    def _calculate_delay(self) -> float:
        """
        Calcula o delay para a próxima tentativa usando backoff exponencial.
        
        Returns:
            float: Tempo de espera em segundos
        """
        # Backoff exponencial com jitter
        delay = min(self.base_delay * (2 ** self.attempts), 30)  # Máximo de 30 segundos
        jitter = delay * 0.1  # 10% de jitter
        return delay + (jitter * (0.5 - time.time() % 1))
        
    def reset(self) -> None:
        """
        Reseta o contador de tentativas.
        """
        self.attempts = 0
        self.is_reconnecting = False
        self.last_attempt_time = None
        
    def get_status(self) -> dict:
        """
        Retorna o status atual do gerenciador de reconexão.
        
        Returns:
            dict: Status atual
        """
        return {
            "is_reconnecting": self.is_reconnecting,
            "attempts": self.attempts,
            "max_attempts": self.max_attempts,
            "last_attempt_time": self.last_attempt_time,
            "next_delay": self._calculate_delay() if self.is_reconnecting else 0
        } 