defmodule DeeperHub.Core.Data.Repo.HealthCheck do
  @moduledoc """
  Módulo para verificação de saúde do banco de dados.
  
  Este módulo fornece funções para verificar se o banco de dados está acessível
  e se o pool de conexões está funcionando corretamente.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
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
