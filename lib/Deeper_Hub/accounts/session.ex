defmodule DeeperHub.Accounts.Session do
  @moduledoc """
  Módulo para gerenciamento de sessões de usuário no DeeperHub.
  
  Este módulo fornece funções para criar, listar e encerrar sessões de usuário,
  permitindo controle sobre dispositivos conectados e monitoramento de atividades.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.Token
  require DeeperHub.Core.Logger
  
  @doc """
  Cria uma nova sessão para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `device_info` - Informações sobre o dispositivo
  
  ## Retorno
    * `{:ok, session_id}` - Se a sessão for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def create(user_id, device_info) do
    # Gera um ID único para a sessão
    session_id = UUID.uuid4()
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Extrai informações do dispositivo
    browser = Map.get(device_info, :browser, "Desconhecido")
    os = Map.get(device_info, :os, "Desconhecido")
    ip = Map.get(device_info, :ip, "Desconhecido")
    location = Map.get(device_info, :location, "Desconhecido")
    
    sql = """
    INSERT INTO user_sessions 
    (id, user_id, browser, os, ip_address, location, last_activity, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    """
    
    params = [
      session_id,
      user_id,
      browser,
      os,
      ip,
      location,
      now,
      now
    ]
    
    case Repo.execute(sql, params) do
      {:ok, _} ->
        Logger.info("Nova sessão criada para usuário: #{user_id}", 
          module: __MODULE__, 
          session_id: session_id, 
          ip: ip
        )
        {:ok, session_id}
        
      {:error, reason} ->
        Logger.error("Erro ao criar sessão: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Lista todas as sessões ativas de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, sessions}` - Lista de sessões ativas
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_active(user_id) do
    sql = """
    SELECT id, browser, os, ip_address, location, last_activity, created_at
    FROM user_sessions
    WHERE user_id = ? AND active = TRUE
    ORDER BY last_activity DESC;
    """
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: rows, columns: columns}} ->
        sessions = Enum.map(rows, fn row ->
          Enum.zip(columns, row) |> Map.new()
        end)
        
        {:ok, sessions}
        
      {:error, reason} ->
        Logger.error("Erro ao listar sessões: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Atualiza a atividade de uma sessão.
  
  ## Parâmetros
    * `session_id` - ID da sessão
  
  ## Retorno
    * `:ok` - Se a atualização for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_activity(session_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = "UPDATE user_sessions SET last_activity = ? WHERE id = ?;"
    
    case Repo.execute(sql, [now, session_id]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Encerra uma sessão específica.
  
  ## Parâmetros
    * `session_id` - ID da sessão
    * `user_id` - ID do usuário (para verificação de segurança)
  
  ## Retorno
    * `:ok` - Se a sessão for encerrada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def terminate(session_id, user_id) do
    # Primeiro verifica se a sessão pertence ao usuário
    sql_check = "SELECT user_id FROM user_sessions WHERE id = ?;"
    
    with {:ok, %{rows: [[^user_id]]}} <- Repo.query(sql_check, [session_id]),
         # Marca a sessão como inativa
         {:ok, _} <- Repo.execute("UPDATE user_sessions SET active = FALSE WHERE id = ?;", [session_id]) do
      
      # Revoga todos os tokens associados a esta sessão
      Token.revoke_by_session(session_id)
      
      Logger.info("Sessão encerrada: #{session_id}", 
        module: __MODULE__, 
        user_id: user_id
      )
      :ok
    else
      {:ok, %{rows: []}} ->
        {:error, :session_not_found}
        
      {:ok, _} ->
        {:error, :unauthorized}
        
      {:error, reason} ->
        Logger.error("Erro ao encerrar sessão: #{inspect(reason)}", 
          module: __MODULE__, 
          session_id: session_id, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Encerra todas as sessões de um usuário, exceto a sessão atual.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `current_session_id` - ID da sessão atual (opcional, não será encerrada)
  
  ## Retorno
    * `{:ok, count}` - Número de sessões encerradas
    * `{:error, reason}` - Se ocorrer um erro
  """
  def terminate_all(user_id, current_session_id \\ nil) do
    # Prepara a query SQL
    {sql, params} = if current_session_id do
      {
        "UPDATE user_sessions SET active = FALSE WHERE user_id = ? AND id != ? AND active = TRUE;",
        [user_id, current_session_id]
      }
    else
      {
        "UPDATE user_sessions SET active = FALSE WHERE user_id = ? AND active = TRUE;",
        [user_id]
      }
    end
    
    case Repo.execute(sql, params) do
      {:ok, %{num_rows: count}} ->
        # Revoga todos os tokens do usuário, exceto os da sessão atual
        Token.revoke_all_for_user(user_id, current_session_id)
        
        Logger.info("#{count} sessões encerradas para usuário: #{user_id}", 
          module: __MODULE__
        )
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao encerrar todas as sessões: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Obtém informações de uma sessão específica.
  
  ## Parâmetros
    * `session_id` - ID da sessão
  
  ## Retorno
    * `{:ok, session}` - Informações da sessão
    * `{:error, reason}` - Se ocorrer um erro
  """
  def get(session_id) do
    sql = """
    SELECT id, user_id, browser, os, ip_address, location, last_activity, created_at, active
    FROM user_sessions
    WHERE id = ?;
    """
    
    case Repo.query(sql, [session_id]) do
      {:ok, %{rows: [row], columns: columns}} ->
        session = Enum.zip(columns, row) |> Map.new()
        {:ok, session}
        
      {:ok, %{rows: []}} ->
        {:error, :session_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar sessão: #{inspect(reason)}", 
          module: __MODULE__, 
          session_id: session_id
        )
        {:error, reason}
    end
  end
end
