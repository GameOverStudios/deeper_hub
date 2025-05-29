defmodule DeeperHub.Accounts.Auth.TokenBlacklist do
  @moduledoc """
  Módulo para gerenciamento da blacklist de tokens revogados no DeeperHub.
  
  Este módulo fornece funções para adicionar tokens à blacklist,
  verificar se um token está na blacklist e limpar tokens expirados.
  
  A blacklist é essencial para implementar a revogação de tokens JWT,
  uma vez que os tokens JWT são auto-contidos e não podem ser invalidados
  sem uma verificação adicional no servidor.
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
    * `{:error, :invalid_input}` - Se algum parâmetro for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, reason}` - Se ocorrer outro erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TokenBlacklist.add_to_blacklist("abc123", "user123", "refresh", ~U[2023-01-01 00:00:00Z])
      :ok
  """
  @spec add_to_blacklist(String.t(), String.t(), String.t(), DateTime.t(), String.t() | nil) :: :ok | {:error, any()}
  def add_to_blacklist(jti, user_id, token_type, expires_at, reason \\ nil)
  def add_to_blacklist(jti, user_id, token_type, expires_at, reason) 
      when is_binary(jti) and is_binary(user_id) and is_binary(token_type) do
    if String.length(jti) == 0 do
      Logger.error("Tentativa de adicionar token com JTI vazio à blacklist", module: __MODULE__)
      {:error, :invalid_input}
    else
      try do
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
            {:error, :database_error}
        end
      rescue
        e in ArgumentError ->
          Logger.error("Erro de argumento ao adicionar token à blacklist: #{Exception.message(e)}", 
            module: __MODULE__, 
            jti: jti, 
            user_id: user_id
          )
          {:error, :invalid_input}
          
        e ->
          Logger.error("Erro inesperado ao adicionar token à blacklist: #{Exception.message(e)}", 
            module: __MODULE__, 
            jti: jti, 
            user_id: user_id
          )
          {:error, :unexpected_error}
      end
    end
  end
  
  def add_to_blacklist(_, _, _, _, _) do
    Logger.error("Tentativa de adicionar token com parâmetros inválidos à blacklist", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Verifica se um token está na blacklist.
  
  ## Parâmetros
    * `jti` - ID único do token (JWT ID)
  
  ## Retorno
    * `{:ok, true}` - Se o token estiver na blacklist
    * `{:ok, false}` - Se o token não estiver na blacklist
    * `{:error, :invalid_input}` - Se o JTI for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TokenBlacklist.is_blacklisted?("abc123")
      {:ok, false}
  """
  @spec is_blacklisted?(String.t()) :: {:ok, boolean()} | {:error, atom()}
  def is_blacklisted?(jti) when is_binary(jti) and jti != "" do
    sql = "SELECT 1 FROM revoked_tokens WHERE jti = ?;"
    
    case Repo.query(sql, [jti]) do
      {:ok, %{rows: []}} ->
        {:ok, false}
        
      {:ok, _} ->
        Logger.debug("Token encontrado na blacklist: #{jti}", module: __MODULE__)
        {:ok, true}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar token na blacklist: #{inspect(reason)}", 
          module: __MODULE__, 
          jti: jti
        )
        {:error, :database_error}
    end
  end
  
  def is_blacklisted?(_) do
    Logger.warn("Tentativa de verificar JTI inválido na blacklist", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Revoga todos os tokens de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `reason` - Motivo da revogação (opcional)
  
  ## Retorno
    * `{:ok, count}` - Número de tokens revogados
    * `{:error, :invalid_input}` - Se o ID do usuário for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TokenBlacklist.revoke_all_for_user("user123", "security_breach")
      {:ok, 5}
  """
  @spec revoke_all_for_user(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, atom()}
  def revoke_all_for_user(user_id, reason \\ nil)
  def revoke_all_for_user(user_id, reason) when is_binary(user_id) and user_id != "" do
    try do
      # Registra a revogação
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      # Primeiro, marca os tokens existentes na tabela user_tokens
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
          
        {:error, db_reason} ->
          Logger.error("Erro ao revogar todos os tokens do usuário: #{inspect(db_reason)}", 
            module: __MODULE__, 
            user_id: user_id
          )
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao revogar tokens do usuário: #{Exception.message(e)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, :unexpected_error}
    end
  end
  
  def revoke_all_for_user(_, _) do
    Logger.warn("Tentativa de revogar tokens com ID de usuário inválido", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Limpa tokens expirados da blacklist.
  
  Esta função deve ser chamada periodicamente para evitar o crescimento
  excessivo da tabela de tokens revogados.
  
  ## Retorno
    * `{:ok, count}` - Número de tokens removidos
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TokenBlacklist.clean_expired()
      {:ok, 15}
  """
  @spec clean_expired() :: {:ok, integer()} | {:error, atom()}
  def clean_expired do
    try do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      sql = "DELETE FROM revoked_tokens WHERE expires_at < ?;"
      
      case Repo.execute(sql, [now]) do
        {:ok, %{rows_affected: count}} ->
          Logger.info("Tokens expirados removidos da blacklist: #{count}", module: __MODULE__)
          {:ok, count}
          
        {:error, reason} ->
          Logger.error("Erro ao limpar tokens expirados: #{inspect(reason)}", module: __MODULE__)
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao limpar tokens expirados: #{Exception.message(e)}", module: __MODULE__)
        {:error, :unexpected_error}
    end
  end
  
  @doc """
  Obtém estatísticas da blacklist de tokens.
  
  ## Retorno
    * `{:ok, stats}` - Mapa contendo as estatísticas
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TokenBlacklist.get_stats()
      {:ok, %{total: 150, expired: 25, active: 125}}
  """
  @spec get_stats() :: {:ok, map()} | {:error, atom()}
  def get_stats do
    try do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      # Consulta para contar tokens ativos e expirados
      sql = """
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN expires_at < ? THEN 1 ELSE 0 END) as expired,
        SUM(CASE WHEN expires_at >= ? THEN 1 ELSE 0 END) as active
      FROM revoked_tokens;
      """
      
      case Repo.query(sql, [now, now]) do
        {:ok, %{rows: [[total, expired, active]], columns: ["total", "expired", "active"]}} ->
          stats = %{
            total: total,
            expired: expired,
            active: active
          }
          
          Logger.info("Estatísticas da blacklist: total=#{total}, ativos=#{active}, expirados=#{expired}", 
            module: __MODULE__
          )
          
          {:ok, stats}
          
        {:error, reason} ->
          Logger.error("Erro ao obter estatísticas da blacklist: #{inspect(reason)}", module: __MODULE__)
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao obter estatísticas da blacklist: #{Exception.message(e)}", module: __MODULE__)
        {:error, :unexpected_error}
    end
  end
end
