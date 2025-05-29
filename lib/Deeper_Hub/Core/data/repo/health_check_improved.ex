defmodule DeeperHub.Core.Data.Repo.HealthCheckImproved do
  @moduledoc """
  Módulo aprimorado para verificação de saúde do banco de dados.
  
  Este módulo fornece funções para verificar se o banco de dados está acessível
  e se o pool de conexões está funcionando corretamente, com mecanismos de
  retry e verificação de processo.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Verifica se o pool de conexões está ativo e disponível.
  
  ## Retorno
    * `:ok` - Se o pool estiver disponível
    * `{:error, :pool_not_found}` - Se o pool não for encontrado
  """
  @spec check_pool_alive() :: :ok | {:error, :pool_not_found}
  def check_pool_alive do
    pool_name = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
                |> Keyword.get(:pool_name, DeeperHub.DBConnectionPool)
    
    Logger.info("Verificando pool de conexões #{inspect(pool_name)}...", module: __MODULE__)
    
    case Process.whereis(pool_name) do
      nil ->
        Logger.error("Pool de conexões #{inspect(pool_name)} não encontrado. Verifique se o supervisor do repositório foi iniciado corretamente.", module: __MODULE__)
        {:error, :pool_not_found}
      pid when is_pid(pid) ->
        case Process.alive?(pid) do
          true ->
            Logger.info("Pool de conexões #{inspect(pool_name)} está ativo (PID: #{inspect(pid)})", module: __MODULE__)
            :ok
          false ->
            Logger.error("Pool de conexões #{inspect(pool_name)} existe mas não está ativo (PID: #{inspect(pid)}). Pode ser necessário reiniciar o supervisor.", module: __MODULE__)
            {:error, :pool_not_found}
        end
    end
  end

  @doc """
  Verifica se o banco de dados está acessível e o pool de conexões está funcionando.
  
  Executa uma consulta simples para verificar se o banco de dados está respondendo.
  
  ## Retorno
    * `:ok` - Se o banco de dados estiver acessível
    * `{:error, reason}` - Se ocorrer algum erro
  """
  @spec check_database() :: :ok | {:error, any()}
  def check_database do
    Logger.debug("Verificando conexão com o banco de dados...", module: __MODULE__)
    
    # Primeiro verifica se o pool está ativo
    with :ok <- check_pool_alive() do
      # Consulta simples para verificar se o banco de dados está respondendo
      sql = "SELECT 1 AS test;"
      
      case DeeperHub.Core.Data.Repo.query(sql) do
        {:ok, rows} when is_list(rows) and length(rows) == 1 ->
          case List.first(rows) do
            [1] ->
              Logger.debug("Conexão com o banco de dados verificada com sucesso.", module: __MODULE__)
              :ok
            unexpected ->
              Logger.error("Resultado inesperado ao verificar conexão com o banco de dados: #{inspect(unexpected)}", module: __MODULE__)
              {:error, :unexpected_result}
          end
        {:ok, unexpected_result} ->
          Logger.error("Formato de resultado inesperado ao verificar conexão com o banco de dados: #{inspect(unexpected_result)}", module: __MODULE__)
          {:error, :unexpected_result}
        {:error, reason} ->
          Logger.error("Falha ao verificar conexão com o banco de dados: #{inspect(reason)}", module: __MODULE__)
          {:error, reason}
      end
    end
  rescue
    exception ->
      Logger.error("Exceção ao verificar conexão com o banco de dados: #{inspect(exception)}", module: __MODULE__)
      {:error, exception}
  end
  
  @doc """
  Aguarda até que o banco de dados esteja acessível ou o número máximo de tentativas seja atingido.
  
  ## Parâmetros
    * `max_attempts` - Número máximo de tentativas (padrão: 5)
    * `wait_time_ms` - Tempo de espera entre tentativas em milissegundos (padrão: 500)
  
  ## Retorno
    * `:ok` - Se o banco de dados estiver acessível
    * `{:error, :max_attempts_reached}` - Se o número máximo de tentativas for atingido
  """
  @spec wait_for_database(integer(), integer()) :: :ok | {:error, :max_attempts_reached}
  def wait_for_database(max_attempts \\ 5, wait_time_ms \\ 500) do
    wait_for_database(1, max_attempts, wait_time_ms)
  end
  
  defp wait_for_database(attempt, max_attempts, wait_time_ms) do
    case check_database() do
      :ok ->
        :ok
      {:error, _reason} ->
        if attempt < max_attempts do
          Logger.warn("Banco de dados ainda não está disponível. Tentativa #{attempt}/#{max_attempts}.", module: __MODULE__)
          Process.sleep(wait_time_ms)
          wait_for_database(attempt + 1, max_attempts, wait_time_ms)
        else
          Logger.error("Banco de dados não está disponível após #{max_attempts} tentativas.", module: __MODULE__)
          {:error, :max_attempts_reached}
        end
    end
  end
end
