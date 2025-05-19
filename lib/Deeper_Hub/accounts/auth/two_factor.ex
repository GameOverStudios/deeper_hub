defmodule DeeperHub.Accounts.Auth.TwoFactor do
  @moduledoc """
  Módulo para autenticação em duas etapas no DeeperHub.
  
  Este módulo fornece funções para gerenciar a autenticação em duas etapas,
  incluindo geração e verificação de códigos temporários, bem como
  configuração e desativação do 2FA para usuários.
  """
  
  alias DeeperHub.Accounts.User
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail.Mail
  require DeeperHub.Core.Logger
  
  # Tempo de expiração do código em minutos
  @code_expiry_minutes 10
  # Tamanho do código de verificação
  @code_length 6
  # Tabela ETS para armazenar os códigos temporários
  @ets_table :two_factor_codes
  
  @doc """
  Inicializa o módulo de autenticação em duas etapas.
  
  Cria a tabela ETS para armazenar os códigos temporários se ela não existir.
  """
  def init do
    if :ets.whereis(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :set, :public, {:read_concurrency, true}])
      Logger.info("Tabela ETS para códigos 2FA inicializada", module: __MODULE__)
    end
    
    :ok
  end
  
  @doc """
  Gera um código de verificação para um usuário e envia por email.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - Email do usuário
    * `device_info` - Informações sobre o dispositivo (opcional)
  
  ## Retorno
    * `{:ok, code}` - Se o código for gerado e enviado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def generate_and_send_code(user_id, email, device_info \\ %{}) do
    # Gera um código numérico aleatório
    code = generate_code()
    
    # Calcula o timestamp de expiração
    expiry = DateTime.utc_now() |> DateTime.add(@code_expiry_minutes * 60, :second)
    
    # Armazena o código na tabela ETS
    :ets.insert(@ets_table, {user_id, code, expiry})
    
    # Registra a geração do código
    Logger.info("Código 2FA gerado para usuário: #{user_id}", 
      module: __MODULE__, 
      email: email, 
      expiry_minutes: @code_expiry_minutes
    )
    
    # Envia o código por email
    case Mail.send_verification_code(
      email,
      code,
      @code_expiry_minutes,
      device_info,
      [priority: :high]
    ) do
      {:ok, _} ->
        {:ok, code}
        
      {:error, reason} ->
        Logger.error("Erro ao enviar código 2FA por email: #{inspect(reason)}", 
          module: __MODULE__, 
          email: email
        )
        {:error, :email_delivery_failed}
    end
  end
  
  @doc """
  Verifica se um código de verificação é válido para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `code` - Código de verificação
  
  ## Retorno
    * `:ok` - Se o código for válido
    * `{:error, reason}` - Se o código for inválido ou expirado
  """
  def verify_code(user_id, code) do
    case :ets.lookup(@ets_table, user_id) do
      [{^user_id, stored_code, expiry}] ->
        cond do
          stored_code != code ->
            {:error, :invalid_code}
            
          DateTime.compare(DateTime.utc_now(), expiry) == :gt ->
            # Remove o código expirado
            :ets.delete(@ets_table, user_id)
            {:error, :code_expired}
            
          true ->
            # Código válido, remove-o após uso
            :ets.delete(@ets_table, user_id)
            :ok
        end
        
      [] ->
        {:error, :code_not_found}
    end
  end
  
  @doc """
  Ativa a autenticação em duas etapas para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `:ok` - Se a ativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def enable_2fa(user_id) do
    # Atualiza o status 2FA do usuário no banco de dados
    update_2fa_status(user_id, true)
  end
  
  @doc """
  Desativa a autenticação em duas etapas para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `:ok` - Se a desativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def disable_2fa(user_id) do
    # Atualiza o status 2FA do usuário no banco de dados
    update_2fa_status(user_id, false)
  end
  
  @doc """
  Verifica se um usuário tem autenticação em duas etapas ativada.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, boolean}` - Status da autenticação em duas etapas
    * `{:error, reason}` - Se ocorrer um erro
  """
  def has_2fa_enabled?(user_id) do
    case User.get(user_id) do
      {:ok, user} ->
        {:ok, Map.get(user, "two_factor_enabled", false)}
        
      error ->
        error
    end
  end
  
  # Funções privadas
  
  # Gera um código numérico aleatório
  defp generate_code do
    1..@code_length
    |> Enum.map(fn _ -> Enum.random(0..9) end)
    |> Enum.join()
  end
  
  # Atualiza o status de autenticação em duas etapas do usuário
  defp update_2fa_status(user_id, enabled) do
    sql = "UPDATE users SET two_factor_enabled = ?, updated_at = ? WHERE id = ?;"
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    alias DeeperHub.Core.Data.Repo
    
    case Repo.execute(sql, [enabled, now, user_id]) do
      {:ok, _} -> 
        Logger.info("Status 2FA atualizado para usuário: #{user_id}, habilitado: #{enabled}", 
          module: __MODULE__
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao atualizar status 2FA: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
end
