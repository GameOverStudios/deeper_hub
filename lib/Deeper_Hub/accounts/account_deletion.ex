defmodule DeeperHub.Accounts.AccountDeletion do
  @moduledoc """
  Módulo para gerenciamento de exclusão de contas no DeeperHub.
  
  Este módulo fornece funções para solicitar, confirmar e processar
  a exclusão de contas de usuários, garantindo conformidade com
  regulamentações de privacidade como LGPD e GDPR.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail
  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Auth.Token
  alias DeeperHub.Accounts.ActivityLog
  require DeeperHub.Core.Logger
  
  # Tempo de expiração da solicitação de exclusão em horas
  @expiry_hours 48
  
  @doc """
  Solicita a exclusão de uma conta de usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - Email do usuário
    * `reason` - Motivo da exclusão (opcional)
  
  ## Retorno
    * `{:ok, confirmation_token}` - Se a solicitação for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def request_deletion(user_id, email, reason \\ nil) do
    # Gera um token de confirmação
    confirmation_token = generate_confirmation_token()
    
    # Calcula a data de expiração
    expiry = DateTime.utc_now() |> DateTime.add(@expiry_hours * 3600, :second) |> DateTime.to_iso8601()
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Serializa o motivo para JSON se fornecido
    reason_json = if reason, do: Jason.encode!(%{reason: reason}), else: "{}"
    
    sql = """
    INSERT INTO account_deletion_requests 
    (user_id, confirmation_token, reason, status, expires_at, created_at)
    VALUES (?, ?, ?, ?, ?, ?);
    """
    
    params = [
      user_id,
      confirmation_token,
      reason_json,
      "pending",
      expiry,
      now
    ]
    
    # Primeiro verifica se já existe uma solicitação pendente
    case check_existing_request(user_id) do
      {:ok, true} ->
        {:error, :request_already_exists}
        
      {:ok, false} ->
        # Cria a solicitação
        case Repo.execute(sql, params) do
          {:ok, _} ->
            # Registra a atividade
            ActivityLog.log_activity(user_id, :account_deletion_requested, %{expires_at: expiry})
            
            # Envia email de confirmação
            case get_user_name(user_id) do
              {:ok, user_name} ->
                confirmation_url = "https://deeperhub.com/conta/confirmar-exclusao?token=#{confirmation_token}"
                cancel_url = "https://deeperhub.com/conta/cancelar-exclusao?token=#{confirmation_token}"
                
                Mail.send_action_confirmation(
                  email,
                  user_name,
                  "exclusão de conta",
                  confirmation_url,
                  cancel_url,
                  [expires_in_hours: @expiry_hours, priority: :high]
                )
                
              _ ->
                # Continua mesmo se não conseguir obter o nome do usuário
                :ok
            end
            
            Logger.info("Solicitação de exclusão de conta criada para usuário: #{user_id}", 
              module: __MODULE__, 
              expiry_hours: @expiry_hours
            )
            
            {:ok, confirmation_token}
            
          {:error, reason} ->
            Logger.error("Erro ao criar solicitação de exclusão de conta: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id
            )
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Confirma a exclusão de uma conta de usuário.
  
  ## Parâmetros
    * `confirmation_token` - Token de confirmação
  
  ## Retorno
    * `{:ok, user_id}` - Se a confirmação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def confirm_deletion(confirmation_token) do
    # Busca a solicitação pelo token
    case get_request_by_token(confirmation_token) do
      {:ok, request} ->
        # Verifica se a solicitação está pendente
        if request["status"] != "pending" do
          {:error, :invalid_request_status}
        else
          # Verifica se a solicitação não expirou
          expiry = DateTime.from_iso8601(request["expires_at"])
          
          case expiry do
            {:ok, expiry_datetime, _} ->
              if DateTime.compare(DateTime.utc_now(), expiry_datetime) == :gt do
                # Solicitação expirada
                update_request_status(request["user_id"], confirmation_token, "expired")
                {:error, :request_expired}
              else
                # Processa a exclusão
                process_account_deletion(request["user_id"], confirmation_token)
              end
              
            _ ->
              {:error, :invalid_expiry_date}
          end
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Cancela uma solicitação de exclusão de conta.
  
  ## Parâmetros
    * `confirmation_token` - Token de confirmação
  
  ## Retorno
    * `{:ok, user_id}` - Se o cancelamento for bem-sucedido
    * `{:error, reason}` - Se ocorrer um erro
  """
  def cancel_deletion_request(confirmation_token) do
    # Busca a solicitação pelo token
    case get_request_by_token(confirmation_token) do
      {:ok, request} ->
        # Verifica se a solicitação está pendente
        if request["status"] != "pending" do
          {:error, :invalid_request_status}
        else
          # Atualiza o status da solicitação
          case update_request_status(request["user_id"], confirmation_token, "cancelled") do
            :ok ->
              # Registra a atividade
              ActivityLog.log_activity(request["user_id"], :account_deletion_cancelled)
              
              Logger.info("Solicitação de exclusão de conta cancelada para usuário: #{request["user_id"]}", 
                module: __MODULE__
              )
              
              {:ok, request["user_id"]}
              
            {:error, reason} ->
              {:error, reason}
          end
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Exporta os dados pessoais de um usuário (para LGPD/GDPR).
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, data}` - Dados pessoais do usuário
    * `{:error, reason}` - Se ocorrer um erro
  """
  def export_personal_data(user_id) do
    # Busca dados do usuário
    with {:ok, user} <- User.get(user_id),
         # Busca atividades do usuário
         {:ok, activities} <- ActivityLog.list_recent_activities(user_id, 1000),
         # Busca outras informações relevantes
         {:ok, preferences} <- get_user_preferences(user_id) do
      
      # Remove dados sensíveis
      user_data = Map.drop(user, ["password_hash"])
      
      # Constrói o objeto de dados pessoais
      data = %{
        user: user_data,
        activities: activities,
        preferences: preferences
      }
      
      # Registra a atividade
      ActivityLog.log_activity(user_id, :personal_data_exported)
      
      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Funções privadas
  
  # Processa a exclusão da conta
  defp process_account_deletion(user_id, confirmation_token) do
    # Atualiza o status da solicitação
    case update_request_status(user_id, confirmation_token, "completed") do
      :ok ->
        # Anonimiza os dados do usuário
        case anonymize_user_data(user_id) do
          :ok ->
            # Revoga todos os tokens do usuário
            Token.revoke_all_for_user(user_id)
            
            # Registra a atividade (para fins de auditoria)
            ActivityLog.log_activity(user_id, :account_deleted)
            
            Logger.info("Conta de usuário excluída: #{user_id}", 
              module: __MODULE__
            )
            
            {:ok, user_id}
            
          {:error, reason} ->
            # Se falhar ao anonimizar, marca a solicitação como falha
            update_request_status(user_id, confirmation_token, "failed")
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Anonimiza os dados do usuário
  defp anonymize_user_data(user_id) do
    # Gera valores anônimos
    anonymous_email = "deleted_#{user_id}@example.com"
    anonymous_username = "deleted_user_#{String.slice(user_id, 0, 8)}"
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Atualiza os dados do usuário
    sql = """
    UPDATE users
    SET 
      email = ?,
      username = ?,
      full_name = NULL,
      bio = NULL,
      avatar_url = NULL,
      status = 'deleted',
      updated_at = ?
    WHERE id = ?;
    """
    
    case Repo.execute(sql, [anonymous_email, anonymous_username, now, user_id]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Verifica se já existe uma solicitação pendente
  defp check_existing_request(user_id) do
    sql = """
    SELECT COUNT(*) FROM account_deletion_requests
    WHERE user_id = ? AND status = 'pending';
    """
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[count]]}} ->
        {:ok, count > 0}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar solicitação existente: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  # Busca uma solicitação pelo token
  defp get_request_by_token(token) do
    sql = """
    SELECT user_id, confirmation_token, reason, status, expires_at, created_at
    FROM account_deletion_requests
    WHERE confirmation_token = ?;
    """
    
    case Repo.query(sql, [token]) do
      {:ok, %{rows: [row], columns: columns}} ->
        request = Enum.zip(columns, row) |> Map.new()
        {:ok, request}
        
      {:ok, %{rows: []}} ->
        {:error, :request_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar solicitação por token: #{inspect(reason)}", 
          module: __MODULE__, 
          token: token
        )
        {:error, reason}
    end
  end
  
  # Atualiza o status de uma solicitação
  defp update_request_status(user_id, token, status) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE account_deletion_requests
    SET status = ?, updated_at = ?
    WHERE user_id = ? AND confirmation_token = ?;
    """
    
    case Repo.execute(sql, [status, now, user_id, token]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Gera um token de confirmação
  defp generate_confirmation_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
  
  # Obtém o nome do usuário
  defp get_user_name(user_id) do
    sql = "SELECT username, full_name FROM users WHERE id = ?;"
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[username, full_name]]}} ->
        if full_name && full_name != "" do
          {:ok, full_name}
        else
          {:ok, username}
        end
        
      {:ok, %{rows: []}} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Obtém as preferências do usuário
  defp get_user_preferences(user_id) do
    sql = """
    SELECT notification_preferences, privacy_settings
    FROM user_preferences
    WHERE user_id = ?;
    """
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[notification_prefs, privacy_settings]]}} ->
        preferences = %{}
        
        # Deserializa as preferências de notificação
        preferences = case Jason.decode(notification_prefs) do
          {:ok, prefs} -> Map.put(preferences, :notification_preferences, prefs)
          _ -> preferences
        end
        
        # Deserializa as configurações de privacidade
        preferences = case Jason.decode(privacy_settings) do
          {:ok, settings} -> Map.put(preferences, :privacy_settings, settings)
          _ -> preferences
        end
        
        {:ok, preferences}
        
      {:ok, %{rows: []}} ->
        # Retorna um objeto vazio se não houver preferências
        {:ok, %{}}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end
