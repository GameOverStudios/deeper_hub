defmodule DeeperHub.Accounts.Auth.TokenBlacklist do
  @moduledoc """
  Módulo para gerenciamento da blacklist de tokens revogados no DeeperHub.
  
  Este módulo fornece funções para adicionar tokens à blacklist,
  verificar se um token está na blacklist e limpar tokens expirados.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Adiciona um token à blacklist.
  
  ## Parâmetros
    * `jti` - ID único do token (JWT ID)
    * `user_id` - ID do usuário
    * `token_type` - Tipo do token (access, refresh)
    * `expires_at` - Data de expiração do token (DateTime)
    * `reason` - Motivo da revogação (opcional)
  
  ## Retorno
    * `:ok` - Se o token for adicionado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec add_to_blacklist(String.t(), String.t(), String.t(), DateTime.t(), String.t() | nil) :: :ok | {:error, any()}
  def add_to_blacklist(jti, user_id, token_type, expires_at, reason \\ nil) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    expires_at_iso = DateTime.to_iso8601(expires_at)
    
    sql = """
    INSERT INTO revoked_tokens (jti, user_id, token_type, expires_at, revoked_at, reason)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT (jti) DO UPDATE SET
      revoked_at = ?,
      reason = COALESCE(?, reason);
    """
    
    params = [jti, user_id, token_type, expires_at_iso, now, reason, now, reason]
    
    case Repo.execute(sql, params) do
      {:ok, _} ->
        Logger.info("Token adicionado à blacklist: #{jti}", 
          module: __MODULE__, 
          user_id: user_id, 
          token_type: token_type
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao adicionar token à blacklist: #{inspect(reason)}", 
          module: __MODULE__, 
          jti: jti, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um token está na blacklist.
  
  ## Parâmetros
    * `jti` - ID único do token (JWT ID)
  
  ## Retorno
    * `{:ok, true}` - Se o token estiver na blacklist
    * `{:ok, false}` - Se o token não estiver na blacklist
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec is_blacklisted?(String.t()) :: {:ok, boolean()} | {:error, any()}
  def is_blacklisted?(jti) do
    sql = "SELECT 1 FROM revoked_tokens WHERE jti = ?;"
    
    case Repo.query(sql, [jti]) do
      {:ok, %{rows: []}} ->
        {:ok, false}
        
      {:ok, _} ->
        {:ok, true}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar token na blacklist: #{inspect(reason)}", 
          module: __MODULE__, 
          jti: jti
        )
        {:error, reason}
    end
  end
  
  @doc """
  Revoga todos os tokens de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `reason` - Motivo da revogação (opcional)
  
  ## Retorno
    * `{:ok, count}` - Número de tokens revogados
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec revoke_all_for_user(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, any()}
  def revoke_all_for_user(user_id, reason \\ nil) do
    # Primeiro, busca todos os tokens ativos do usuário no Guardian
    # Isso é uma implementação simplificada, pois o Guardian não armazena tokens
    # Em uma implementação real, seria necessário integrar com o armazenamento de tokens
    
    # Registra a revogação
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    INSERT INTO revoked_tokens (jti, user_id, token_type, expires_at, revoked_at, reason)
    SELECT jti, user_id, token_type, expires_at, ?, ?
    FROM user_tokens
    WHERE user_id = ? AND expires_at > ?;
    """
    
    case Repo.execute(sql, [now, reason, user_id, now]) do
      {:ok, %{rows_affected: count}} ->
        Logger.info("Todos os tokens do usuário #{user_id} foram revogados: #{count} tokens", 
          module: __MODULE__, 
          reason: reason
        )
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao revogar todos os tokens do usuário: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Limpa tokens expirados da blacklist.
  
  ## Retorno
    * `{:ok, count}` - Número de tokens removidos
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec clean_expired() :: {:ok, integer()} | {:error, any()}
  def clean_expired do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = "DELETE FROM revoked_tokens WHERE expires_at < ?;"
    
    case Repo.execute(sql, [now]) do
      {:ok, %{rows_affected: count}} ->
        Logger.info("Tokens expirados removidos da blacklist: #{count}", module: __MODULE__)
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao limpar tokens expirados: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
