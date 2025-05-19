defmodule DeeperHub.Accounts.ActivityLog do
  @moduledoc """
  Módulo para registro e consulta de atividades do usuário no DeeperHub.
  
  Este módulo fornece funções para registrar ações importantes realizadas
  pelos usuários, como login, alteração de senha, e outras atividades
  relevantes para segurança e auditoria.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Tipos de atividade
  @activity_types %{
    login: "login",
    logout: "logout",
    password_change: "password_change",
    password_reset: "password_reset",
    profile_update: "profile_update",
    email_change: "email_change",
    security_settings_change: "security_settings_change",
    two_factor_enabled: "two_factor_enabled",
    two_factor_disabled: "two_factor_disabled",
    device_added: "device_added",
    device_removed: "device_removed",
    session_terminated: "session_terminated",
    all_sessions_terminated: "all_sessions_terminated",
    account_deletion_requested: "account_deletion_requested",
    account_deletion_cancelled: "account_deletion_cancelled",
    account_deleted: "account_deleted",
    personal_data_exported: "personal_data_exported",
    # Eventos de segurança
    auth_attempt_blocked: "auth_attempt_blocked",
    auth_failure: "auth_failure",
    suspicious_activity: "suspicious_activity",
    ip_blocked: "ip_blocked",
    rate_limit_exceeded: "rate_limit_exceeded"
  }
  
  @doc """
  Registra uma nova atividade para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `activity_type` - Tipo de atividade (atom)
    * `metadata` - Metadados adicionais sobre a atividade (opcional)
    * `ip_address` - Endereço IP de onde a atividade foi realizada (opcional)
  
  ## Retorno
    * `{:ok, activity_id}` - Se a atividade for registrada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def log_activity(user_id, activity_type, metadata \\ %{}, ip_address \\ nil) do
    # Valida o tipo de atividade
    activity_type_str = Map.get(@activity_types, activity_type)
    
    if activity_type_str do
      # Gera um ID único para a atividade
      activity_id = UUID.uuid4()
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      # Serializa os metadados para JSON
      metadata_json = Jason.encode!(metadata)
      
      sql = """
      INSERT INTO user_activity_logs 
      (id, user_id, activity_type, metadata, ip_address, created_at)
      VALUES (?, ?, ?, ?, ?, ?);
      """
      
      params = [
        activity_id,
        user_id,
        activity_type_str,
        metadata_json,
        ip_address || "desconhecido",
        now
      ]
      
      case Repo.execute(sql, params) do
        {:ok, _} ->
          Logger.info("Atividade registrada: #{activity_type_str} para usuário: #{user_id}", 
            module: __MODULE__, 
            activity_id: activity_id, 
            ip: ip_address
          )
          {:ok, activity_id}
          
        {:error, reason} ->
          Logger.error("Erro ao registrar atividade: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id, 
            activity_type: activity_type_str
          )
          {:error, reason}
      end
    else
      Logger.error("Tipo de atividade inválido: #{inspect(activity_type)}", 
        module: __MODULE__, 
        user_id: user_id
      )
      {:error, :invalid_activity_type}
    end
  end
  
  @doc """
  Lista as atividades recentes de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `limit` - Número máximo de atividades a retornar (padrão: 20)
    * `offset` - Deslocamento para paginação (padrão: 0)
  
  ## Retorno
    * `{:ok, activities}` - Lista de atividades
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_recent_activities(user_id, limit \\ 20, offset \\ 0) do
    sql = """
    SELECT id, activity_type, metadata, ip_address, created_at
    FROM user_activity_logs
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?;
    """
    
    case Repo.query(sql, [user_id, limit, offset]) do
      {:ok, %{rows: rows, columns: columns}} ->
        activities = Enum.map(rows, fn row ->
          activity = Enum.zip(columns, row) |> Map.new()
          
          # Deserializa os metadados do JSON
          case Jason.decode(activity["metadata"]) do
            {:ok, metadata} ->
              Map.put(activity, "metadata", metadata)
              
            {:error, _} ->
              # Mantém os metadados como string em caso de erro
              activity
          end
        end)
        
        {:ok, activities}
        
      {:error, reason} ->
        Logger.error("Erro ao listar atividades: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Conta o número total de atividades de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, count}` - Número total de atividades
    * `{:error, reason}` - Se ocorrer um erro
  """
  def count_activities(user_id) do
    sql = "SELECT COUNT(*) FROM user_activity_logs WHERE user_id = ?;"
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[count]]}} ->
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao contar atividades: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Busca atividades por tipo.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `activity_type` - Tipo de atividade (atom)
    * `limit` - Número máximo de atividades a retornar (padrão: 20)
    * `offset` - Deslocamento para paginação (padrão: 0)
  
  ## Retorno
    * `{:ok, activities}` - Lista de atividades
    * `{:error, reason}` - Se ocorrer um erro
  """
  def find_by_type(user_id, activity_type, limit \\ 20, offset \\ 0) do
    # Valida o tipo de atividade
    activity_type_str = Map.get(@activity_types, activity_type)
    
    if activity_type_str do
      sql = """
      SELECT id, activity_type, metadata, ip_address, created_at
      FROM user_activity_logs
      WHERE user_id = ? AND activity_type = ?
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?;
      """
      
      case Repo.query(sql, [user_id, activity_type_str, limit, offset]) do
        {:ok, %{rows: rows, columns: columns}} ->
          activities = Enum.map(rows, fn row ->
            activity = Enum.zip(columns, row) |> Map.new()
            
            # Deserializa os metadados do JSON
            case Jason.decode(activity["metadata"]) do
              {:ok, metadata} ->
                Map.put(activity, "metadata", metadata)
                
              {:error, _} ->
                # Mantém os metadados como string em caso de erro
                activity
            end
          end)
          
          {:ok, activities}
          
        {:error, reason} ->
          Logger.error("Erro ao buscar atividades por tipo: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id, 
            activity_type: activity_type_str
          )
          {:error, reason}
      end
    else
      Logger.error("Tipo de atividade inválido: #{inspect(activity_type)}", 
        module: __MODULE__, 
        user_id: user_id
      )
      {:error, :invalid_activity_type}
    end
  end
  
  @doc """
  Busca atividades por período.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `start_date` - Data de início (DateTime)
    * `end_date` - Data de fim (DateTime)
    * `limit` - Número máximo de atividades a retornar (padrão: 50)
    * `offset` - Deslocamento para paginação (padrão: 0)
  
  ## Retorno
    * `{:ok, activities}` - Lista de atividades
    * `{:error, reason}` - Se ocorrer um erro
  """
  def find_by_period(user_id, start_date, end_date, limit \\ 50, offset \\ 0) do
    start_date_str = DateTime.to_iso8601(start_date)
    end_date_str = DateTime.to_iso8601(end_date)
    
    sql = """
    SELECT id, activity_type, metadata, ip_address, created_at
    FROM user_activity_logs
    WHERE user_id = ? AND created_at BETWEEN ? AND ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?;
    """
    
    case Repo.query(sql, [user_id, start_date_str, end_date_str, limit, offset]) do
      {:ok, %{rows: rows, columns: columns}} ->
        activities = Enum.map(rows, fn row ->
          activity = Enum.zip(columns, row) |> Map.new()
          
          # Deserializa os metadados do JSON
          case Jason.decode(activity["metadata"]) do
            {:ok, metadata} ->
              Map.put(activity, "metadata", metadata)
              
            {:error, _} ->
              # Mantém os metadados como string em caso de erro
              activity
          end
        end)
        
        {:ok, activities}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar atividades por período: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Obtém os tipos de atividade disponíveis.
  
  ## Retorno
    * Mapa com os tipos de atividade
  """
  def get_activity_types do
    @activity_types
  end
  
  @doc """
  Registra um evento de segurança no sistema.
  
  Esta função é utilizada para registrar eventos relacionados à segurança,
  como tentativas de autenticação bloqueadas, atividades suspeitas,
  bloqueios de IP e outros eventos relevantes para a segurança do sistema.
  
  ## Parâmetros
    * `event_type` - Tipo do evento de segurança (atom ou string)
    * `user_id` - ID do usuário (pode ser nil se não estiver associado a um usuário específico)
    * `details` - Detalhes do evento (mapa com informações adicionais)
  
  ## Retorno
    * `{:ok, event_id}` - Se o evento for registrado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def log_security_event(event_type, user_id, details) do
    # Converte o tipo de evento para string se for um atom
    event_type_str = if is_atom(event_type), do: Map.get(@activity_types, event_type), else: event_type
    
    # Gera um ID único para o evento
    event_id = UUID.uuid4()
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Extrai o IP do mapa de detalhes ou usa "desconhecido"
    ip_address = Map.get(details, :ip) || Map.get(details, "ip", "desconhecido")
    
    # Serializa os detalhes para JSON
    details_json = Jason.encode!(details)
    
    # Tabela específica para eventos de segurança
    sql = """
    INSERT INTO security_events 
    (id, event_type, user_id, details, ip_address, created_at)
    VALUES (?, ?, ?, ?, ?, ?);
    """
    
    params = [
      event_id,
      event_type_str,
      user_id,  # Pode ser nil
      details_json,
      ip_address,
      now
    ]
    
    # Tenta inserir na tabela de eventos de segurança
    case Repo.execute(sql, params) do
      {:ok, _} ->
        Logger.info("Evento de segurança registrado: #{event_type_str}", 
          module: __MODULE__, 
          event_id: event_id, 
          ip: ip_address,
          user_id: user_id
        )
        {:ok, event_id}
        
      {:error, reason} ->
        # Se a tabela não existir, tenta registrar como atividade normal
        if is_binary(reason) and String.contains?(reason, "no such table") do
          # Fallback: registra como atividade normal do usuário se possível
          if user_id do
            log_activity(user_id, :suspicious_activity, details, ip_address)
          else
            Logger.error("Falha ao registrar evento de segurança: #{inspect(reason)}", 
              module: __MODULE__, 
              event_type: event_type_str
            )
            {:error, reason}
          end
        else
          Logger.error("Erro ao registrar evento de segurança: #{inspect(reason)}", 
            module: __MODULE__, 
            event_type: event_type_str
          )
          {:error, reason}
        end
    end
  rescue
    e ->
      Logger.error("Exceção ao registrar evento de segurança: #{inspect(e)}", 
        module: __MODULE__, 
        event_type: event_type
      )
      {:error, :exception}
  end
end
