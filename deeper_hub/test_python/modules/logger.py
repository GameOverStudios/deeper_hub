#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import logging.handlers
import os
import json
from datetime import datetime
from typing import Any, Dict, Optional
from ..config import get_config

class DeeperHubLogger:
    """
    Logger personalizado para o cliente DeeperHub com suporte a rotação de arquivos,
    formatação JSON e diferentes níveis de log.
    """
    
    def __init__(self, name: str = "deeper_hub_client"):
        self.config = get_config()
        self.logger = logging.getLogger(name)
        self._setup_logger()
        
    def _setup_logger(self) -> None:
        """Configura o logger com handlers e formatters apropriados."""
        self.logger.setLevel(self.config["logging"]["level"])
        
        # Cria diretório de logs se não existir
        log_dir = os.path.dirname(self.config["logging"]["file"])
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)
            
        # Handler para arquivo com rotação
        file_handler = logging.handlers.RotatingFileHandler(
            self.config["logging"]["file"],
            maxBytes=self.config["logging"]["max_size"],
            backupCount=self.config["logging"]["backup_count"]
        )
        file_handler.setFormatter(self._get_json_formatter())
        self.logger.addHandler(file_handler)
        
        # Handler para console
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(self._get_console_formatter())
        self.logger.addHandler(console_handler)
        
    def _get_json_formatter(self) -> logging.Formatter:
        """Retorna um formatter para logs em JSON."""
        class JsonFormatter(logging.Formatter):
            def format(self, record: logging.LogRecord) -> str:
                log_data = {
                    "timestamp": datetime.utcnow().isoformat(),
                    "level": record.levelname,
                    "message": record.getMessage(),
                    "module": record.module,
                    "function": record.funcName,
                    "line": record.lineno
                }
                
                if hasattr(record, "extra_data"):
                    log_data["extra_data"] = record.extra_data
                    
                if record.exc_info:
                    log_data["exception"] = self.formatException(record.exc_info)
                    
                return json.dumps(log_data)
                
        return JsonFormatter()
        
    def _get_console_formatter(self) -> logging.Formatter:
        """Retorna um formatter para logs no console."""
        return logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
    def _log(self, level: int, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Método interno para logging com dados extras."""
        if extra_data:
            self.logger.log(level, message, extra={"extra_data": extra_data})
        else:
            self.logger.log(level, message)
            
    def debug(self, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Log de nível DEBUG."""
        self._log(logging.DEBUG, message, extra_data)
        
    def info(self, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Log de nível INFO."""
        self._log(logging.INFO, message, extra_data)
        
    def warning(self, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Log de nível WARNING."""
        self._log(logging.WARNING, message, extra_data)
        
    def error(self, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Log de nível ERROR."""
        self._log(logging.ERROR, message, extra_data)
        
    def critical(self, message: str, extra_data: Optional[Dict[str, Any]] = None) -> None:
        """Log de nível CRITICAL."""
        self._log(logging.CRITICAL, message, extra_data)
        
    def exception(self, message: str, exc_info: Optional[Exception] = None) -> None:
        """Log de exceção com stack trace."""
        self.logger.exception(message, exc_info=exc_info)
        
    def websocket_event(self, event_type: str, data: Dict[str, Any]) -> None:
        """Log específico para eventos WebSocket."""
        self.info(
            f"WebSocket Event: {event_type}",
            {"event_type": event_type, "data": data}
        )
        
    def api_request(self, method: str, endpoint: str, params: Optional[Dict[str, Any]] = None) -> None:
        """Log específico para requisições API."""
        self.debug(
            f"API Request: {method} {endpoint}",
            {"method": method, "endpoint": endpoint, "params": params}
        )
        
    def api_response(self, method: str, endpoint: str, status: int, response: Any) -> None:
        """Log específico para respostas API."""
        self.debug(
            f"API Response: {method} {endpoint} - Status: {status}",
            {"method": method, "endpoint": endpoint, "status": status, "response": response}
        )

# Cria uma instância global do logger
logger = DeeperHubLogger()

def get_logger(name=None, level=None):
    """Obtém o logger global ou cria um novo com nome específico."""
    if name is None:
        return logger
        
    new_logger = DeeperHubLogger(name=name)
    if level is not None:
        new_logger.set_level(level)
    return new_logger
