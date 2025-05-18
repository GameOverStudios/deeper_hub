defmodule Deeper_Hub.Core.WebSockets.Auth.Token.TokenService do
  @moduledoc """
  Serviço para gerenciamento de tokens.
  
  Este módulo fornece uma interface comum para todos os tipos de tokens,
  incluindo JWT e tokens opacos para diferentes finalidades.
  """
  
  # Removido alias não utilizado
  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
  alias Deeper_Hub.Core.WebSockets.Auth.Token.OpaqueTokenService
  
  @doc """
  Gera um par de tokens JWT (acesso e refresh).
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
    - `expiry`: Tempo de expiração do token de refresh em segundos (opcional)
    
  ## Retorno
  
    - `{:ok, access_token, refresh_token, claims}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def generate_jwt_pair(user_id, expiry \\ nil) do
    JwtService.generate_token_pair(user_id, expiry)
  end
  
  @doc """
  Verifica um token JWT.
  
  ## Parâmetros
  
    - `token`: Token JWT a ser verificado
    
  ## Retorno
  
    - `{:ok, claims}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def verify_jwt(token) do
    JwtService.verify_token(token)
  end
  
  @doc """
  Revoga um token JWT.
  
  ## Parâmetros
  
    - `token`: Token JWT a ser revogado
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def revoke_jwt(token) do
    JwtService.revoke_token(token)
  end
  
  @doc """
  Gera um token opaco para uma finalidade específica.
  
  ## Parâmetros
  
    - `purpose`: Finalidade do token (`:password_reset`, `:email_verification`, `:api`)
    - `identifier`: Identificador associado ao token (geralmente user_id)
    - `expiry`: Tempo de expiração em segundos (opcional)
    - `metadata`: Metadados adicionais (opcional)
    
  ## Retorno
  
    - `{:ok, token, expires_at}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def generate_opaque_token(purpose, identifier, expiry \\ nil, metadata \\ %{}) do
    OpaqueTokenService.generate_token(purpose, identifier, expiry, metadata)
  end
  
  @doc """
  Verifica um token opaco.
  
  ## Parâmetros
  
    - `token`: Token opaco a ser verificado
    - `purpose`: Finalidade esperada do token
    
  ## Retorno
  
    - `{:ok, data}` em caso de sucesso, onde `data` contém o identificador e metadados
    - `{:error, reason}` em caso de falha
  """
  def verify_opaque_token(token, purpose) do
    OpaqueTokenService.verify_token(token, purpose)
  end
  
  @doc """
  Revoga um token opaco.
  
  ## Parâmetros
  
    - `token`: Token opaco a ser revogado
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def revoke_opaque_token(token) do
    OpaqueTokenService.revoke_token(token)
  end
  
  @doc """
  Revoga todos os tokens opacos para um identificador e finalidade específicos.
  
  ## Parâmetros
  
    - `identifier`: Identificador associado aos tokens
    - `purpose`: Finalidade dos tokens a serem revogados
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def revoke_all_opaque_tokens(identifier, purpose) do
    OpaqueTokenService.revoke_all_tokens(identifier, purpose)
  end
end
