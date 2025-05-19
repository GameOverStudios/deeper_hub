defmodule DeeperHub.Accounts.DeviceManager do
  @moduledoc """
  Módulo para gerenciamento de dispositivos no DeeperHub.
  
  Este módulo fornece funções para gerenciar dispositivos confiáveis,
  detectar novos dispositivos e notificar o usuário sobre atividades suspeitas.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail
  require DeeperHub.Core.Logger
  
  @doc """
  Registra um novo dispositivo para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `device_info` - Informações sobre o dispositivo
    * `trusted` - Se o dispositivo deve ser marcado como confiável
  
  ## Retorno
    * `{:ok, device_id}` - Se o dispositivo for registrado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def register_device(user_id, device_info, trusted \\ false) do
    # Gera um ID único para o dispositivo
    device_id = UUID.uuid4()
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    # Extrai informações do dispositivo
    browser = Map.get(device_info, :browser, "Desconhecido")
    os = Map.get(device_info, :os, "Desconhecido")
    ip = Map.get(device_info, :ip, "Desconhecido")
    location = Map.get(device_info, :location, "Desconhecido")
    
    sql = """
    INSERT INTO user_devices 
    (id, user_id, browser, os, ip_address, location, trusted, last_used, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    """
    
    params = [
      device_id,
      user_id,
      browser,
      os,
      ip,
      location,
      trusted,
      now,
      now
    ]
    
    case Repo.execute(sql, params) do
      {:ok, _} ->
        Logger.info("Novo dispositivo registrado para usuário: #{user_id}", 
          module: __MODULE__, 
          device_id: device_id, 
          ip: ip,
          trusted: trusted
        )
        {:ok, device_id}
        
      {:error, reason} ->
        Logger.error("Erro ao registrar dispositivo: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Lista todos os dispositivos de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, devices}` - Lista de dispositivos
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_devices(user_id) do
    sql = """
    SELECT id, browser, os, ip_address, location, trusted, last_used, created_at
    FROM user_devices
    WHERE user_id = ?
    ORDER BY last_used DESC;
    """
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: rows, columns: columns}} ->
        devices = Enum.map(rows, fn row ->
          Enum.zip(columns, row) |> Map.new()
        end)
        
        {:ok, devices}
        
      {:error, reason} ->
        Logger.error("Erro ao listar dispositivos: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Marca um dispositivo como confiável.
  
  ## Parâmetros
    * `device_id` - ID do dispositivo
    * `user_id` - ID do usuário (para verificação de segurança)
  
  ## Retorno
    * `:ok` - Se o dispositivo for marcado como confiável com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def trust_device(device_id, user_id) do
    # Primeiro verifica se o dispositivo pertence ao usuário
    sql_check = "SELECT user_id FROM user_devices WHERE id = ?;"
    
    with {:ok, %{rows: [[^user_id]]}} <- Repo.query(sql_check, [device_id]),
         # Marca o dispositivo como confiável
         {:ok, _} <- Repo.execute("UPDATE user_devices SET trusted = TRUE WHERE id = ?;", [device_id]) do
      
      Logger.info("Dispositivo marcado como confiável: #{device_id}", 
        module: __MODULE__, 
        user_id: user_id
      )
      :ok
    else
      {:ok, %{rows: []}} ->
        {:error, :device_not_found}
        
      {:ok, _} ->
        {:error, :unauthorized}
        
      {:error, reason} ->
        Logger.error("Erro ao marcar dispositivo como confiável: #{inspect(reason)}", 
          module: __MODULE__, 
          device_id: device_id, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Remove um dispositivo da lista de dispositivos do usuário.
  
  ## Parâmetros
    * `device_id` - ID do dispositivo
    * `user_id` - ID do usuário (para verificação de segurança)
  
  ## Retorno
    * `:ok` - Se o dispositivo for removido com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def remove_device(device_id, user_id) do
    # Primeiro verifica se o dispositivo pertence ao usuário
    sql_check = "SELECT user_id FROM user_devices WHERE id = ?;"
    
    with {:ok, %{rows: [[^user_id]]}} <- Repo.query(sql_check, [device_id]),
         # Remove o dispositivo
         {:ok, _} <- Repo.execute("DELETE FROM user_devices WHERE id = ?;", [device_id]) do
      
      Logger.info("Dispositivo removido: #{device_id}", 
        module: __MODULE__, 
        user_id: user_id
      )
      :ok
    else
      {:ok, %{rows: []}} ->
        {:error, :device_not_found}
        
      {:ok, _} ->
        {:error, :unauthorized}
        
      {:error, reason} ->
        Logger.error("Erro ao remover dispositivo: #{inspect(reason)}", 
          module: __MODULE__, 
          device_id: device_id, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Atualiza a data de último uso de um dispositivo.
  
  ## Parâmetros
    * `device_id` - ID do dispositivo
  
  ## Retorno
    * `:ok` - Se a atualização for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_last_used(device_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = "UPDATE user_devices SET last_used = ? WHERE id = ?;"
    
    case Repo.execute(sql, [now, device_id]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Verifica se um dispositivo é confiável para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `device_info` - Informações sobre o dispositivo
  
  ## Retorno
    * `{:ok, device_id}` - Se o dispositivo for confiável, retorna seu ID
    * `{:ok, :new_device}` - Se o dispositivo não for conhecido
    * `{:error, reason}` - Se ocorrer um erro
  """
  def check_device(user_id, device_info) do
    # Extrai informações do dispositivo
    browser = Map.get(device_info, :browser, "Desconhecido")
    os = Map.get(device_info, :os, "Desconhecido")
    
    sql = """
    SELECT id, trusted FROM user_devices 
    WHERE user_id = ? AND browser = ? AND os = ?
    ORDER BY last_used DESC LIMIT 1;
    """
    
    case Repo.query(sql, [user_id, browser, os]) do
      {:ok, %{rows: [[device_id, trusted]]}} ->
        # Atualiza a data de último uso
        update_last_used(device_id)
        
        if trusted do
          {:ok, device_id}
        else
          {:ok, {:untrusted_device, device_id}}
        end
        
      {:ok, %{rows: []}} ->
        {:ok, :new_device}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar dispositivo: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Notifica o usuário sobre um login em um novo dispositivo.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - Email do usuário
    * `device_info` - Informações sobre o dispositivo
  
  ## Retorno
    * `:ok` - Se a notificação for enviada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def notify_new_device_login(user_id, email, device_info) do
    # Busca informações do usuário
    case get_user_name(user_id) do
      {:ok, user_name} ->
        # Envia email de notificação
        case Mail.send_new_device_login(
          email,
          user_name,
          device_info,
          "https://deeperhub.com/seguranca/dispositivos",
          [priority: :high]
        ) do
          {:ok, _} ->
            Logger.info("Notificação de novo dispositivo enviada para usuário: #{user_id}", 
              module: __MODULE__, 
              email: email
            )
            :ok
            
          {:error, reason} ->
            Logger.error("Erro ao enviar notificação de novo dispositivo: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id, 
              email: email
            )
            {:error, :notification_failed}
        end
        
      {:error, reason} ->
        Logger.error("Erro ao buscar nome do usuário: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  # Funções privadas
  
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
end
