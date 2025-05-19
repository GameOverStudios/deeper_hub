defmodule DeeperHub.Accounts.Auth.Logout do
  @moduledoc """
  Módulo para gerenciamento de logout de usuários no DeeperHub.
  
  Este módulo fornece funções para encerrar sessões de usuário,
  revogar tokens e registrar atividades de logout.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.ActivityLog
  alias DeeperHub.Accounts.SessionManager
  require DeeperHub.Core.Logger
  
  @doc """
  Realiza o logout de um usuário.
  
  ## Parâmetros
    * `session_id` - ID da sessão a ser encerrada
    * `opts` - Opções adicionais:
      * `:ip_address` - Endereço IP do cliente
      * `:all_sessions` - Se deve encerrar todas as sessões do usuário
  
  ## Retorno
    * `:ok` - Se o logout for bem-sucedido
    * `{:error, :session_not_found}` - Se a sessão não for encontrada
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec logout(String.t(), Keyword.t()) :: :ok | {:error, atom()} | {:error, any()}
  def logout(session_id, opts \\ []) do
    ip_address = Keyword.get(opts, :ip_address, "desconhecido")
    all_sessions = Keyword.get(opts, :all_sessions, false)
    
    # Busca informações da sessão
    sql = "SELECT user_id FROM user_sessions WHERE id = ?;"
    
    case Repo.query(sql, [session_id]) do
      {:ok, %{rows: [[user_id]]}} ->
        if all_sessions do
          # Encerra todas as sessões do usuário
          case SessionManager.invalidate_all_sessions(user_id, "user_logout", session_id) do
            {:ok, count} ->
              # Registra a atividade
              ActivityLog.log_activity(user_id, :logout_all_sessions, %{
                count: count
              }, ip_address)
              
              Logger.info("Todas as sessões do usuário #{user_id} foram encerradas (#{count})", 
                module: __MODULE__
              )
              
              :ok
              
            {:error, reason} ->
              Logger.error("Erro ao encerrar todas as sessões: #{inspect(reason)}", 
                module: __MODULE__, 
                user_id: user_id
              )
              {:error, reason}
          end
        else
          # Encerra apenas a sessão atual
          case SessionManager.invalidate_session(session_id, "user_logout") do
            :ok ->
              # Registra a atividade
              ActivityLog.log_activity(user_id, :logout, %{
                session_id: session_id
              }, ip_address)
              
              Logger.info("Sessão encerrada: #{session_id}", 
                module: __MODULE__, 
                user_id: user_id
              )
              
              :ok
              
            {:error, reason} ->
              Logger.error("Erro ao encerrar sessão: #{inspect(reason)}", 
                module: __MODULE__, 
                session_id: session_id
              )
              {:error, reason}
          end
        end
        
      {:ok, %{rows: []}} ->
        # Sessão não encontrada
        Logger.warn("Tentativa de logout com sessão inexistente: #{session_id}", 
          module: __MODULE__
        )
        {:error, :session_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar informações da sessão: #{inspect(reason)}", 
          module: __MODULE__, 
          session_id: session_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Encerra sessões inativas de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `inactivity_period` - Período de inatividade em segundos
  
  ## Retorno
    * `{:ok, count}` - Número de sessões encerradas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec logout_inactive_sessions(String.t(), integer()) :: {:ok, integer()} | {:error, any()}
  def logout_inactive_sessions(user_id, inactivity_period) do
    # Calcula o timestamp limite
    limit = DateTime.utc_now() 
            |> DateTime.add(-inactivity_period, :second) 
            |> DateTime.to_iso8601()
    
    # Busca sessões inativas
    sql = """
    SELECT id
    FROM user_sessions
    WHERE user_id = ? AND last_activity_at < ?;
    """
    
    case Repo.query(sql, [user_id, limit]) do
      {:ok, %{rows: rows}} ->
        # Encerra cada sessão inativa
        Enum.each(rows, fn [session_id] ->
          SessionManager.invalidate_session(session_id, "inactivity_timeout")
        end)
        
        count = length(rows)
        
        if count > 0 do
          # Registra a atividade
          ActivityLog.log_activity(user_id, :logout_inactive_sessions, %{
            count: count,
            inactivity_period: inactivity_period
          })
          
          Logger.info("#{count} sessões inativas do usuário #{user_id} foram encerradas", 
            module: __MODULE__
          )
        end
        
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao encerrar sessões inativas: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Encerra todas as sessões de um usuário após alteração de senha.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `except_session_id` - ID da sessão a ser mantida (opcional)
  
  ## Retorno
    * `{:ok, count}` - Número de sessões encerradas
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec logout_after_password_change(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, any()}
  def logout_after_password_change(user_id, except_session_id \\ nil) do
    # Verifica a política de sessão
    if DeeperHub.Accounts.SessionPolicy.should_invalidate_on_password_change?(user_id) do
      # Encerra todas as sessões, exceto a atual (se fornecida)
      case SessionManager.invalidate_all_sessions(user_id, "password_changed", except_session_id) do
        {:ok, count} ->
          # Registra a atividade
          ActivityLog.log_activity(user_id, :logout_after_password_change, %{
            count: count,
            except_session_id: except_session_id
          })
          
          Logger.info("#{count} sessões do usuário #{user_id} foram encerradas após alteração de senha", 
            module: __MODULE__
          )
          
          {:ok, count}
          
        {:error, reason} ->
          Logger.error("Erro ao encerrar sessões após alteração de senha: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id
          )
          {:error, reason}
      end
    else
      # Política não exige encerramento de sessões
      {:ok, 0}
    end
  end
end
