defmodule Deeper_Hub.Core.WebSockets.Auth.Token.BlacklistService do
  @moduledoc """
  Serviço para gerenciamento da blacklist de tokens.
  
  Este módulo fornece funções para adicionar, verificar e limpar
  tokens na blacklist.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist
  
  @doc """
  Adiciona um token à blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser adicionado
    - `expiry`: Timestamp de expiração do token
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def add_to_blacklist(token, expiry) do
    TokenBlacklist.add(token, expiry)
  end
  
  @doc """
  Verifica se um token está na blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser verificado
    
  ## Retorno
  
    - `true` se o token estiver na blacklist
    - `false` caso contrário
  """
  def is_blacklisted?(token) do
    TokenBlacklist.contains?(token)
  end
  
  @doc """
  Remove um token da blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser removido
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def remove_from_blacklist(token) do
    TokenBlacklist.remove(token)
  end
  
  @doc """
  Limpa tokens expirados da blacklist.
  
  ## Retorno
  
    - Número de tokens removidos
  """
  def cleanup_expired_tokens do
    # Obtém o timestamp atual
    now = DateTime.utc_now() |> DateTime.to_unix()
    
    # Obtém todos os tokens da blacklist
    tokens = TokenBlacklist.list()
    
    # Filtra tokens expirados
    expired_tokens = Enum.filter(tokens, fn {_token, expiry} ->
      expiry < now
    end)
    
    # Remove tokens expirados
    Enum.each(expired_tokens, fn {token, _expiry} ->
      TokenBlacklist.remove(token)
    end)
    
    # Registra a limpeza
    count = length(expired_tokens)
    
    if count > 0 do
      Logger.info("Tokens expirados removidos da blacklist", %{
        module: __MODULE__,
        count: count
      })
    end
    
    count
  end
  
  @doc """
  Limpa toda a blacklist.
  
  ## Retorno
  
    - Número de tokens removidos
  """
  def clear_blacklist do
    # Obtém todos os tokens da blacklist
    tokens = TokenBlacklist.list()
    
    # Remove todos os tokens
    Enum.each(tokens, fn {token, _expiry} ->
      TokenBlacklist.remove(token)
    end)
    
    # Registra a limpeza
    count = length(tokens)
    
    if count > 0 do
      Logger.info("Blacklist de tokens limpa", %{
        module: __MODULE__,
        count: count
      })
    end
    
    count
  end
end
