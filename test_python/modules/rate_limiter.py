"""
Sistema de rate limiting para o cliente DeeperHub.
"""
import time
from collections import deque
from typing import Deque, Dict, Optional
from ..config import get_config

class RateLimiter:
    """
    Implementa rate limiting usando o algoritmo Token Bucket.
    """
    
    def __init__(self):
        self.config = get_config()
        self.rate_limit = self.config["rate_limit"]
        self._requests: Dict[str, Deque[float]] = {}
        
    def _cleanup_old_requests(self, key: str, window: int) -> None:
        """Remove requisições antigas do histórico."""
        now = time.time()
        while self._requests[key] and now - self._requests[key][0] > window:
            self._requests[key].popleft()
            
    def can_make_request(self, key: str = "default") -> bool:
        """
        Verifica se uma nova requisição pode ser feita.
        
        Args:
            key: Identificador para o rate limit (ex: endpoint, usuário)
            
        Returns:
            bool: True se a requisição pode ser feita, False caso contrário
        """
        if key not in self._requests:
            self._requests[key] = deque()
            
        now = time.time()
        window = 60  # 1 minuto
        
        # Limpa requisições antigas
        self._cleanup_old_requests(key, window)
        
        # Verifica limite de requisições por minuto
        if len(self._requests[key]) >= self.rate_limit["requests_per_minute"]:
            return False
            
        # Verifica limite de burst
        if len(self._requests[key]) >= self.rate_limit["burst_limit"]:
            # Verifica se já passou tempo suficiente desde a última requisição
            if now - self._requests[key][-1] < (window / self.rate_limit["requests_per_minute"]):
                return False
                
        # Adiciona a nova requisição ao histórico
        self._requests[key].append(now)
        return True
        
    def wait_if_needed(self, key: str = "default") -> None:
        """
        Espera o tempo necessário antes de fazer uma nova requisição.
        
        Args:
            key: Identificador para o rate limit
        """
        while not self.can_make_request(key):
            time.sleep(0.1)  # Espera 100ms antes de tentar novamente
            
    def get_remaining_requests(self, key: str = "default") -> int:
        """
        Retorna o número de requisições restantes no período atual.
        
        Args:
            key: Identificador para o rate limit
            
        Returns:
            int: Número de requisições restantes
        """
        if key not in self._requests:
            return self.rate_limit["requests_per_minute"]
            
        self._cleanup_old_requests(key, 60)
        return self.rate_limit["requests_per_minute"] - len(self._requests[key])
        
    def get_reset_time(self, key: str = "default") -> Optional[float]:
        """
        Retorna o tempo até o reset do rate limit.
        
        Args:
            key: Identificador para o rate limit
            
        Returns:
            Optional[float]: Tempo em segundos até o reset, ou None se não houver limite
        """
        if key not in self._requests or not self._requests[key]:
            return None
            
        now = time.time()
        oldest_request = self._requests[key][0]
        return max(0, 60 - (now - oldest_request)) 