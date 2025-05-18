#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import os
import sys
from datetime import datetime
import colorama
from colorama import Fore, Style

# Inicializa o colorama para funcionar no Windows
colorama.init()

class DeeperHubLogger:
    """
    Sistema de logs para o cliente DeeperHub.
    Implementa diferentes níveis de log com cores e formatação.
    """
    
    # Níveis de log
    DEBUG = 10
    INFO = 20
    WARNING = 30
    ERROR = 40
    CRITICAL = 50
    
    # Dicionário de níveis de log para fácil acesso
    LOG_LEVELS = {
        "debug": DEBUG,
        "info": INFO,
        "warning": WARNING,
        "error": ERROR,
        "critical": CRITICAL
    }
    
    # Cores para os diferentes níveis de log
    COLORS = {
        DEBUG: Fore.CYAN,
        INFO: Fore.GREEN,
        WARNING: Fore.YELLOW,
        ERROR: Fore.RED,
        CRITICAL: Fore.MAGENTA + Style.BRIGHT
    }
    
    # Prefixos para os diferentes níveis de log
    PREFIXES = {
        DEBUG: "🔍 DEBUG",
        INFO: "ℹ️ INFO",
        WARNING: "⚠️ AVISO",
        ERROR: "❌ ERRO",
        CRITICAL: "🔥 CRÍTICO"
    }
    
    def __init__(self, name="DeeperHub", level=INFO, log_to_file=True, log_dir="logs"):
        """Inicializa o logger com o nome e nível especificados."""
        self.name = name
        self.level = level
        self.log_to_file = log_to_file
        self.log_dir = log_dir
        
        # Configura o logger do Python
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        self.logger.handlers = []  # Remove handlers existentes
        
        # Configura o handler para console
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(level)
        self.logger.addHandler(console_handler)
        
        # Configura o handler para arquivo se necessário
        if log_to_file:
            self._setup_file_handler()
    
    def _setup_file_handler(self):
        """Configura o handler para gravar logs em arquivo."""
        try:
            # Cria o diretório de logs se não existir
            if not os.path.exists(self.log_dir):
                os.makedirs(self.log_dir)
            
            # Nome do arquivo de log com data e hora
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_file = os.path.join(self.log_dir, f"{self.name}_{timestamp}.log")
            
            # Configura o handler para arquivo
            file_handler = logging.FileHandler(log_file, encoding='utf-8')
            file_handler.setLevel(self.level)
            
            # Formato para o arquivo de log
            formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            file_handler.setFormatter(formatter)
            
            self.logger.addHandler(file_handler)
            self.log_file = log_file
            self.debug(f"Log sendo gravado em: {log_file}")
        except Exception as e:
            self.error(f"Erro ao configurar log em arquivo: {e}")
    
    def _log(self, level, message, *args, **kwargs):
        """Método interno para processar logs."""
        if level < self.level:
            return
            
        # Formata a mensagem
        if args:
            message = message % args
            
        # Adiciona informações extras se fornecidas
        if kwargs:
            extra_info = " | ".join(f"{k}={v}" for k, v in kwargs.items())
            message = f"{message} [{extra_info}]"
            
        # Imprime no console com cores
        color = self.COLORS.get(level, "")
        prefix = self.PREFIXES.get(level, "LOG")
        print(f"{color}{prefix}: {message}{Style.RESET_ALL}")
        
        # Registra no logger do Python para gravar em arquivo
        self.logger.log(level, message)
    
    def debug(self, message, *args, **kwargs):
        """Registra uma mensagem de debug."""
        self._log(self.DEBUG, message, *args, **kwargs)
    
    def info(self, message, *args, **kwargs):
        """Registra uma mensagem informativa."""
        self._log(self.INFO, message, *args, **kwargs)
    
    def warning(self, message, *args, **kwargs):
        """Registra um aviso."""
        self._log(self.WARNING, message, *args, **kwargs)
    
    def error(self, message, *args, **kwargs):
        """Registra um erro."""
        self._log(self.ERROR, message, *args, **kwargs)
    
    def critical(self, message, *args, **kwargs):
        """Registra um erro crítico."""
        self._log(self.CRITICAL, message, *args, **kwargs)
    
    def set_level(self, level):
        """Altera o nível de log."""
        self.level = level
        self.logger.setLevel(level)
        for handler in self.logger.handlers:
            handler.setLevel(level)
    
    def log_request(self, message_type, payload):
        """Registra uma requisição enviada ao servidor."""
        self.debug(f"Enviando requisição: {message_type}", payload=payload)
    
    def log_response(self, response):
        """Registra uma resposta recebida do servidor."""
        if isinstance(response, dict) and "type" in response:
            msg_type = response["type"]
            if msg_type.endswith(".success"):
                self.info(f"Resposta de sucesso: {msg_type}", payload=response.get("payload", {}))
            elif msg_type.endswith(".error"):
                self.error(f"Resposta de erro: {msg_type}", payload=response.get("payload", {}))
            else:
                self.debug(f"Resposta recebida: {msg_type}", payload=response.get("payload", {}))
        else:
            self.debug("Resposta recebida", response=response)
    
    def log_exception(self, exception, context=None):
        """Registra uma exceção com contexto opcional."""
        if context:
            self.error(f"Exceção em {context}: {exception}")
        else:
            self.error(f"Exceção: {exception}")

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
