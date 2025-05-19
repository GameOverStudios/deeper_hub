defmodule DeeperHub.Accounts.UserProfile do
  @moduledoc """
  Módulo para gerenciamento de perfil de usuário no DeeperHub.
  
  Este módulo fornece funções para gerenciar informações de perfil,
  preferências e configurações pessoais dos usuários.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.User
  require DeeperHub.Core.Logger
  
  @doc """
  Atualiza o perfil de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `attrs` - Mapa com os atributos a serem atualizados
  
  ## Retorno
    * `{:ok, user}` - Se o perfil for atualizado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_profile(user_id, attrs) do
    allowed_attrs = Map.take(attrs, [:username, :full_name, :bio, :avatar_url])
    
    if Enum.empty?(allowed_attrs) do
      {:error, :no_fields_to_update}
    else
      User.update(user_id, allowed_attrs)
    end
  end
  
  @doc """
  Atualiza as preferências de notificação de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `preferences` - Mapa com as preferências de notificação
  
  ## Retorno
    * `:ok` - Se as preferências forem atualizadas com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_notification_preferences(user_id, preferences) do
    # Valida as preferências
    validated_prefs = validate_notification_preferences(preferences)
    
    # Serializa as preferências para JSON
    prefs_json = Jason.encode!(validated_prefs)
    
    sql = """
    UPDATE user_preferences 
    SET notification_preferences = ?, updated_at = ?
    WHERE user_id = ?;
    """
    
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    case Repo.execute(sql, [prefs_json, now, user_id]) do
      {:ok, %{num_rows: 0}} ->
        # Nenhuma linha atualizada, precisa inserir
        insert_preferences(user_id, prefs_json)
        
      {:ok, _} ->
        Logger.info("Preferências de notificação atualizadas para usuário: #{user_id}", 
          module: __MODULE__
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao atualizar preferências de notificação: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Obtém as preferências de notificação de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, preferences}` - Preferências de notificação
    * `{:error, reason}` - Se ocorrer um erro
  """
  def get_notification_preferences(user_id) do
    sql = "SELECT notification_preferences FROM user_preferences WHERE user_id = ?;"
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[prefs_json]]}} ->
        case Jason.decode(prefs_json) do
          {:ok, prefs} -> {:ok, prefs}
          {:error, reason} -> {:error, reason}
        end
        
      {:ok, %{rows: []}} ->
        # Retorna preferências padrão se não existirem
        {:ok, default_notification_preferences()}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar preferências de notificação: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Atualiza a configuração de privacidade de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `privacy_settings` - Mapa com as configurações de privacidade
  
  ## Retorno
    * `:ok` - Se as configurações forem atualizadas com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_privacy_settings(user_id, privacy_settings) do
    # Valida as configurações de privacidade
    validated_settings = validate_privacy_settings(privacy_settings)
    
    # Serializa as configurações para JSON
    settings_json = Jason.encode!(validated_settings)
    
    sql = """
    UPDATE user_preferences 
    SET privacy_settings = ?, updated_at = ?
    WHERE user_id = ?;
    """
    
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    case Repo.execute(sql, [settings_json, now, user_id]) do
      {:ok, %{num_rows: 0}} ->
        # Nenhuma linha atualizada, precisa inserir
        insert_privacy_settings(user_id, settings_json)
        
      {:ok, _} ->
        Logger.info("Configurações de privacidade atualizadas para usuário: #{user_id}", 
          module: __MODULE__
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao atualizar configurações de privacidade: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Obtém as configurações de privacidade de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, settings}` - Configurações de privacidade
    * `{:error, reason}` - Se ocorrer um erro
  """
  def get_privacy_settings(user_id) do
    sql = "SELECT privacy_settings FROM user_preferences WHERE user_id = ?;"
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[settings_json]]}} ->
        case Jason.decode(settings_json) do
          {:ok, settings} -> {:ok, settings}
          {:error, reason} -> {:error, reason}
        end
        
      {:ok, %{rows: []}} ->
        # Retorna configurações padrão se não existirem
        {:ok, default_privacy_settings()}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar configurações de privacidade: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Atualiza a foto de perfil de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `avatar_url` - URL da nova foto de perfil
  
  ## Retorno
    * `{:ok, user}` - Se a foto for atualizada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_avatar(user_id, avatar_url) do
    User.update(user_id, %{avatar_url: avatar_url})
  end
  
  # Funções privadas
  
  # Insere novas preferências de notificação
  defp insert_preferences(user_id, prefs_json) do
    sql = """
    INSERT INTO user_preferences 
    (user_id, notification_preferences, created_at, updated_at)
    VALUES (?, ?, ?, ?);
    """
    
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    case Repo.execute(sql, [user_id, prefs_json, now, now]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Insere novas configurações de privacidade
  defp insert_privacy_settings(user_id, settings_json) do
    sql = """
    INSERT INTO user_preferences 
    (user_id, privacy_settings, created_at, updated_at)
    VALUES (?, ?, ?, ?);
    """
    
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    case Repo.execute(sql, [user_id, settings_json, now, now]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Valida as preferências de notificação
  defp validate_notification_preferences(preferences) do
    default_prefs = default_notification_preferences()
    
    # Garante que apenas as chaves válidas sejam usadas
    Map.take(preferences, Map.keys(default_prefs))
    |> Map.merge(default_prefs, fn _k, user_val, _default_val -> user_val end)
  end
  
  # Valida as configurações de privacidade
  defp validate_privacy_settings(settings) do
    default_settings = default_privacy_settings()
    
    # Garante que apenas as chaves válidas sejam usadas
    Map.take(settings, Map.keys(default_settings))
    |> Map.merge(default_settings, fn _k, user_val, _default_val -> user_val end)
  end
  
  # Preferências de notificação padrão
  defp default_notification_preferences do
    %{
      "email_login_alerts" => true,
      "email_security_alerts" => true,
      "email_system_updates" => true,
      "email_marketing" => false,
      "push_notifications" => true
    }
  end
  
  # Configurações de privacidade padrão
  defp default_privacy_settings do
    %{
      "profile_visibility" => "registered_users",
      "show_online_status" => true,
      "allow_search_engines" => false,
      "show_activity_status" => true
    }
  end
end
