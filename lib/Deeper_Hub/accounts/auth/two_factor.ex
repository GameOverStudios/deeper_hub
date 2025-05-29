defmodule DeeperHub.Accounts.Auth.TwoFactor do
  @moduledoc """
  Módulo para autenticação em duas etapas no DeeperHub.
  
  Este módulo fornece funções para gerenciar a autenticação em duas etapas (2FA),
  incluindo geração e verificação de códigos temporários, bem como
  configuração e desativação do 2FA para usuários.
  
  A autenticação em duas etapas aumenta significativamente a segurança das contas
  ao exigir uma segunda forma de verificação além da senha.
  """
  
  alias DeeperHub.Accounts.User
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail
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
  Esta função deve ser chamada durante a inicialização da aplicação.
  
  ## Retorno
    * `:ok` - Se a inicialização for bem-sucedida
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.init()
      :ok
  """
  @spec init() :: :ok
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
    * `{:error, :email_delivery_failed}` - Se ocorrer um erro ao enviar o email
    * `{:error, :ets_error}` - Se ocorrer um erro ao armazenar o código
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.generate_and_send_code("user123", "usuario@exemplo.com")
      {:ok, "123456"}
  """
  @spec generate_and_send_code(String.t(), String.t(), map()) :: {:ok, String.t()} | {:error, atom()}
  def generate_and_send_code(user_id, email, device_info \\ %{}) do
    # Gera um código numérico aleatório
    code = generate_code()
    
    # Calcula o timestamp de expiração
    expiry = DateTime.utc_now() |> DateTime.add(@code_expiry_minutes * 60, :second)
    
    # Armazena o código na tabela ETS
    try do
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
    catch
      :error, reason ->
        Logger.error("Erro ao armazenar código 2FA na tabela ETS: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, :ets_error}
    end
  end
  
  @doc """
  Verifica se um código de verificação é válido para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `code` - Código de verificação
  
  ## Retorno
    * `:ok` - Se o código for válido
    * `{:error, :invalid_code}` - Se o código for inválido
    * `{:error, :code_expired}` - Se o código estiver expirado
    * `{:error, :code_not_found}` - Se não houver código para o usuário
    * `{:error, :ets_error}` - Se ocorrer um erro ao acessar a tabela ETS
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.verify_code("user123", "123456")
      :ok
  """
  @spec verify_code(String.t(), String.t()) :: :ok | {:error, atom()}
  def verify_code(user_id, code) do
    try do
      case :ets.lookup(@ets_table, user_id) do
        [{^user_id, stored_code, expiry}] ->
          cond do
            stored_code != code ->
              Logger.info("Tentativa de verificação 2FA com código inválido", 
                module: __MODULE__, 
                user_id: user_id
              )
              {:error, :invalid_code}
              
            DateTime.compare(DateTime.utc_now(), expiry) == :gt ->
              # Remove o código expirado
              :ets.delete(@ets_table, user_id)
              Logger.info("Tentativa de verificação 2FA com código expirado", 
                module: __MODULE__, 
                user_id: user_id
              )
              {:error, :code_expired}
              
            true ->
              # Código válido, remove-o após uso
              :ets.delete(@ets_table, user_id)
              Logger.info("Verificação 2FA bem-sucedida", 
                module: __MODULE__, 
                user_id: user_id
              )
              :ok
          end
          
        [] ->
          Logger.info("Tentativa de verificação 2FA com código não encontrado", 
            module: __MODULE__, 
            user_id: user_id
          )
          {:error, :code_not_found}
      end
    catch
      :error, reason ->
        Logger.error("Erro ao verificar código 2FA: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, :ets_error}
    end
  end
  
  @doc """
  Ativa a autenticação em duas etapas para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `:ok` - Se a ativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.enable_2fa("user123")
      :ok
  """
  @spec enable_2fa(String.t()) :: :ok | {:error, any()}
  def enable_2fa(user_id) do
    # Atualiza o status 2FA do usuário no banco de dados
    case update_2fa_status(user_id, true) do
      :ok -> 
        Logger.info("Autenticação em duas etapas ativada", 
          module: __MODULE__, 
          user_id: user_id
        )
        :ok
      error -> error
    end
  end
  
  @doc """
  Desativa a autenticação em duas etapas para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `:ok` - Se a desativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.disable_2fa("user123")
      :ok
  """
  @spec disable_2fa(String.t()) :: :ok | {:error, any()}
  def disable_2fa(user_id) do
    # Atualiza o status 2FA do usuário no banco de dados
    case update_2fa_status(user_id, false) do
      :ok -> 
        Logger.info("Autenticação em duas etapas desativada", 
          module: __MODULE__, 
          user_id: user_id
        )
        :ok
      error -> error
    end
  end
  
  @doc """
  Verifica se um usuário tem autenticação em duas etapas ativada.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, boolean}` - Status da autenticação em duas etapas
    * `{:error, :not_found}` - Se o usuário não for encontrado
    * `{:error, reason}` - Se ocorrer outro erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.TwoFactor.has_2fa_enabled?("user123")
      {:ok, true}
  """
  @spec has_2fa_enabled?(String.t()) :: {:ok, boolean()} | {:error, any()}
  def has_2fa_enabled?(user_id) do
    case User.get(user_id) do
      {:ok, user} ->
        {:ok, Map.get(user, "two_factor_enabled", false)}
        
      {:error, :not_found} = error ->
        Logger.warn("Tentativa de verificar 2FA para usuário inexistente", 
          module: __MODULE__, 
          user_id: user_id
        )
        error
        
      {:error, reason} = error ->
        Logger.error("Erro ao verificar status 2FA: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        error
    end
  end
  
  # Funções privadas
  
  @doc false
  # Gera um código numérico aleatório
  @spec generate_code() :: String.t()
  defp generate_code do
    1..@code_length
    |> Enum.map(fn _ -> Enum.random(0..9) end)
    |> Enum.join()
  end
  
  @doc false
  # Atualiza o status de autenticação em duas etapas do usuário
  @spec update_2fa_status(String.t(), boolean()) :: :ok | {:error, any()}
  defp update_2fa_status(user_id, enabled) do
    sql = "UPDATE users SET two_factor_enabled = ?, updated_at = ? WHERE id = ?;"
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    alias DeeperHub.Core.Data.Repo
    
    case Repo.execute(sql, [enabled, now, user_id]) do
      {:ok, %{rows_affected: 1}} -> 
        Logger.info("Status 2FA atualizado para usuário: #{user_id}, habilitado: #{enabled}", 
          module: __MODULE__
        )
        :ok
        
      {:ok, %{rows_affected: 0}} ->
        Logger.warn("Tentativa de atualizar status 2FA para usuário inexistente", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao atualizar status 2FA: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Limpa códigos expirados da tabela ETS.
  
  Esta função deve ser chamada periodicamente para evitar o crescimento
  excessivo da tabela ETS.
  
  ## Retorno
    * `{:ok, count}` - Número de códigos removidos
    * `{:error, :ets_error}` - Se ocorrer um erro ao acessar a tabela ETS
  """
  @spec clean_expired_codes() :: {:ok, integer()} | {:error, atom()}
  def clean_expired_codes do
    try do
      now = DateTime.utc_now()
      count = :ets.foldl(
        fn {user_id, _code, expiry}, acc ->
          if DateTime.compare(now, expiry) == :gt do
            :ets.delete(@ets_table, user_id)
            acc + 1
          else
            acc
          end
        end,
        0,
        @ets_table
      )
      
      Logger.info("Códigos 2FA expirados removidos: #{count}", module: __MODULE__)
      {:ok, count}
    catch
      :error, reason ->
        Logger.error("Erro ao limpar códigos 2FA expirados: #{inspect(reason)}", module: __MODULE__)
        {:error, :ets_error}
    end
  end
end
