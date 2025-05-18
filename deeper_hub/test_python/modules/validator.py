"""
Sistema de validação para o cliente DeeperHub.
"""
import re
from typing import Any, Dict, List, Optional, Tuple, Union
from ..config import get_config, AUTH_CONSTANTS, MESSAGE_CONSTANTS, USER_CONSTANTS

class Validator:
    """
    Sistema de validação para dados de entrada do cliente.
    """
    
    def __init__(self):
        self.config = get_config()
        
    def validate_username(self, username: str) -> Tuple[bool, Optional[str]]:
        """
        Valida um nome de usuário.
        
        Args:
            username: Nome de usuário a ser validado
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not username:
            return False, "Nome de usuário não pode ser vazio"
            
        if len(username) < USER_CONSTANTS["MIN_USERNAME_LENGTH"]:
            return False, f"Nome de usuário deve ter pelo menos {USER_CONSTANTS['MIN_USERNAME_LENGTH']} caracteres"
            
        if len(username) > USER_CONSTANTS["MAX_USERNAME_LENGTH"]:
            return False, f"Nome de usuário deve ter no máximo {USER_CONSTANTS['MAX_USERNAME_LENGTH']} caracteres"
            
        if not re.match(r"^[a-zA-Z0-9_-]+$", username):
            return False, "Nome de usuário deve conter apenas letras, números, underscores e hífens"
            
        return True, None
        
    def validate_email(self, email: str) -> Tuple[bool, Optional[str]]:
        """
        Valida um endereço de email.
        
        Args:
            email: Email a ser validado
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not email:
            return False, "Email não pode ser vazio"
            
        if len(email) > USER_CONSTANTS["EMAIL_MAX_LENGTH"]:
            return False, f"Email deve ter no máximo {USER_CONSTANTS['EMAIL_MAX_LENGTH']} caracteres"
            
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if not re.match(email_pattern, email):
            return False, "Email inválido"
            
        return True, None
        
    def validate_password(self, password: str) -> Tuple[bool, Optional[str]]:
        """
        Valida uma senha.
        
        Args:
            password: Senha a ser validada
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not password:
            return False, "Senha não pode ser vazia"
            
        if len(password) < AUTH_CONSTANTS["PASSWORD_MIN_LENGTH"]:
            return False, f"Senha deve ter pelo menos {AUTH_CONSTANTS['PASSWORD_MIN_LENGTH']} caracteres"
            
        if len(password) > AUTH_CONSTANTS["PASSWORD_MAX_LENGTH"]:
            return False, f"Senha deve ter no máximo {AUTH_CONSTANTS['PASSWORD_MAX_LENGTH']} caracteres"
            
        # Verifica complexidade da senha
        if not re.search(r"[A-Z]", password):
            return False, "Senha deve conter pelo menos uma letra maiúscula"
            
        if not re.search(r"[a-z]", password):
            return False, "Senha deve conter pelo menos uma letra minúscula"
            
        if not re.search(r"\d", password):
            return False, "Senha deve conter pelo menos um número"
            
        if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
            return False, "Senha deve conter pelo menos um caractere especial"
            
        return True, None
        
    def validate_channel_name(self, name: str) -> Tuple[bool, Optional[str]]:
        """
        Valida um nome de canal.
        
        Args:
            name: Nome do canal a ser validado
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not name:
            return False, "Nome do canal não pode ser vazio"
            
        if len(name) > MESSAGE_CONSTANTS["MAX_CHANNEL_NAME_LENGTH"]:
            return False, f"Nome do canal deve ter no máximo {MESSAGE_CONSTANTS['MAX_CHANNEL_NAME_LENGTH']} caracteres"
            
        if not re.match(r"^[a-zA-Z0-9_-]+$", name):
            return False, "Nome do canal deve conter apenas letras, números, underscores e hífens"
            
        return True, None
        
    def validate_channel_description(self, description: str) -> Tuple[bool, Optional[str]]:
        """
        Valida uma descrição de canal.
        
        Args:
            description: Descrição do canal a ser validada
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not description:
            return True, None  # Descrição é opcional
            
        if len(description) > MESSAGE_CONSTANTS["MAX_CHANNEL_DESCRIPTION_LENGTH"]:
            return False, f"Descrição do canal deve ter no máximo {MESSAGE_CONSTANTS['MAX_CHANNEL_DESCRIPTION_LENGTH']} caracteres"
            
        return True, None
        
    def validate_message(self, message: str) -> Tuple[bool, Optional[str]]:
        """
        Valida uma mensagem.
        
        Args:
            message: Mensagem a ser validada
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not message:
            return False, "Mensagem não pode ser vazia"
            
        if len(message) > MESSAGE_CONSTANTS["MAX_MESSAGE_LENGTH"]:
            return False, f"Mensagem deve ter no máximo {MESSAGE_CONSTANTS['MAX_MESSAGE_LENGTH']} caracteres"
            
        return True, None
        
    def validate_pagination(self, page: int, limit: int) -> Tuple[bool, Optional[str]]:
        """
        Valida parâmetros de paginação.
        
        Args:
            page: Número da página
            limit: Limite de itens por página
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if page < 1:
            return False, "Número da página deve ser maior que zero"
            
        if limit < 1 or limit > 100:
            return False, "Limite deve estar entre 1 e 100"
            
        return True, None
        
    def validate_metadata(self, metadata: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        """
        Valida metadados.
        
        Args:
            metadata: Metadados a serem validados
            
        Returns:
            Tuple[bool, Optional[str]]: (é_válido, mensagem_erro)
        """
        if not isinstance(metadata, dict):
            return False, "Metadados devem ser um dicionário"
            
        for key, value in metadata.items():
            if not isinstance(key, str):
                return False, "Chaves dos metadados devem ser strings"
                
            if not isinstance(value, (str, int, float, bool, list, dict, type(None))):
                return False, f"Valor inválido para a chave '{key}'"
                
        return True, None 