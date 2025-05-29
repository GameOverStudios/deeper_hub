defmodule DeeperHub.Core.Data.Repo do
  @moduledoc """
  Interface principal para operações de banco de dados usando DBConnection.

  Este módulo fornece funções para executar consultas SQL, transações e outras
  operações de banco de dados usando o adaptador Exqlite.Connection.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Importa o protocolo Query para Exqlite
  alias Exqlite.Query, as: Q

  # Helper para obter o nome do pool configurado
  defp pool_name do
    # Usando o caminho completo do módulo para garantir que a configuração seja encontrada
    Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
    |> Keyword.get(:pool_name, DeeperHub.DBConnectionPool) # Padrão se não configurado
  end

  # Helper para criar uma query Exqlite a partir de uma string SQL
  defp prepare_query(sql_string) do
    # O Exqlite.Query é apenas um struct com o campo statement
    %Q{statement: sql_string}
  end

  @doc """
  Executa uma consulta SQL que não necessariamente retorna linhas (ex: INSERT, UPDATE, DELETE).
  Retorna `{:ok, result_map}` ou `{:error, exception}`.
  O `result_map` tipicamente contém `%{num_rows: integer, rows: list_of_tuples_or_maps}`.
  
  Esta função inclui mecanismos de retry para lidar com falhas temporárias de conexão.
  """
  def execute(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Executando SQL: #{sql_string} com parâmetros: #{inspect(params)}", module: __MODULE__)

    # Configuração de retry
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_delay_ms = Keyword.get(opts, :retry_delay_ms, 200)
    
    # Remove opções de retry para não passar para o DBConnection
    opts = Keyword.drop(opts, [:max_retries, :retry_delay_ms])
    
    # Executa com retry
    execute_with_retry(sql_string, params, opts, 1, max_retries, retry_delay_ms)
  end
  
  # Função auxiliar para executar com retry
  defp execute_with_retry(sql_string, params, opts, attempt, max_retries, retry_delay_ms) do
    # Cria uma query Exqlite
    query = prepare_query(sql_string)

    # Tenta executar a query usando o DBConnection
    try do
      case DBConnection.prepare_execute(pool_name(), query, params, opts) do
        {:ok, _query_struct, result} ->
          Logger.debug("Execução bem-sucedida. Resultado: #{inspect(result)}", module: __MODULE__)
          {:ok, result}
        {:error, exception} ->
          handle_execution_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception)
      end
    rescue
      exception ->
        handle_execution_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception)
    end
  end
  
  # Função auxiliar para lidar com erros de execução
  defp handle_execution_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception) do
    error_message = "Falha na execução. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}"
    
    # Verifica se deve tentar novamente
    if attempt < max_retries and retriable_error?(exception) do
      Logger.warn("#{error_message} - Tentativa #{attempt}/#{max_retries}. Tentando novamente em #{retry_delay_ms}ms...", module: __MODULE__)
      Process.sleep(retry_delay_ms)
      execute_with_retry(sql_string, params, opts, attempt + 1, max_retries, retry_delay_ms)
    else
      if attempt > 1 do
        Logger.error("#{error_message} - Desistindo após #{attempt} tentativas.", module: __MODULE__)
      else
        Logger.error(error_message, module: __MODULE__)
      end
      {:error, exception}
    end
  end
  
  # Determina se um erro é retriable
  defp retriable_error?(exception) do
    # Adicione aqui lógica para determinar quais erros são retriable
    # Por exemplo, erros de timeout, conexão, ou banco de dados ocupado
    case exception do
      %DBConnection.ConnectionError{} -> true
      %Exqlite.Error{message: message} ->
        String.contains?(message, "busy") or
        String.contains?(message, "locked") or
        String.contains?(message, "timeout")
      _ -> false
    end
  end

  @doc """
  Executa uma consulta SQL esperada para retornar linhas (ex: SELECT).
  Retorna `{:ok, rows_list}` ou `{:error, exception}`.
  
  Esta função inclui mecanismos de retry para lidar com falhas temporárias de conexão.
  """
  def query(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Consultando SQL: #{sql_string} com parâmetros: #{inspect(params)}", module: __MODULE__)

    # Configuração de retry
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_delay_ms = Keyword.get(opts, :retry_delay_ms, 200)
    
    # Remove opções de retry para não passar para o DBConnection
    opts = Keyword.drop(opts, [:max_retries, :retry_delay_ms])
    
    # Executa com retry
    query_with_retry(sql_string, params, opts, 1, max_retries, retry_delay_ms)
  end
  
  # Função auxiliar para executar consulta com retry
  defp query_with_retry(sql_string, params, opts, attempt, max_retries, retry_delay_ms) do
    # Cria uma query Exqlite
    query = prepare_query(sql_string)

    # Tenta executar a query usando o DBConnection
    try do
      case DBConnection.prepare_execute(pool_name(), query, params, opts) do
        {:ok, _query_struct, %{rows: rows} = result} ->
          Logger.debug("Consulta bem-sucedida. Linhas: #{inspect(rows)}, Resultado completo: #{inspect(result)}", module: __MODULE__)
          {:ok, rows}
        {:ok, _query_struct, result} -> # Fallback se o formato do resultado for diferente
          Logger.warn("Consulta bem-sucedida mas o formato do resultado não foi %{rows: ...}. Resultado completo: #{inspect(result)}", module: __MODULE__)
          {:ok, result} # Ou talvez um erro, dependendo da rigidez desejada
        {:error, exception} ->
          handle_query_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception)
      end
    rescue
      exception ->
        handle_query_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception)
    end
  end
  
  # Função auxiliar para lidar com erros de consulta
  defp handle_query_error(sql_string, params, opts, attempt, max_retries, retry_delay_ms, exception) do
    error_message = "Falha na consulta. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}"
    
    # Verifica se deve tentar novamente
    if attempt < max_retries and retriable_error?(exception) do
      Logger.warn("#{error_message} - Tentativa #{attempt}/#{max_retries}. Tentando novamente em #{retry_delay_ms}ms...", module: __MODULE__)
      Process.sleep(retry_delay_ms)
      query_with_retry(sql_string, params, opts, attempt + 1, max_retries, retry_delay_ms)
    else
      if attempt > 1 do
        Logger.error("#{error_message} - Desistindo após #{attempt} tentativas.", module: __MODULE__)
      else
        Logger.error(error_message, module: __MODULE__)
      end
      {:error, exception}
    end
  end

  @doc """
  Executa uma função dentro de uma transação de banco de dados.
  A função `fun` recebe a referência da conexão.
  Retorna `{:ok, result_of_fun}` ou `{:error, reason}`.
  """
  def transaction(fun, opts \\ []) when is_function(fun, 1) do
    Logger.info("Iniciando transação.", module: __MODULE__)
    case DBConnection.transaction(pool_name(), fun, opts) do
      {:ok, result} ->
        Logger.info("Transação confirmada com sucesso. Resultado: #{inspect(result)}", module: __MODULE__)
        {:ok, result}
      {:error, reason} ->
        Logger.error("Transação falhou ou foi revertida. Motivo: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  # TODO: Implement Repo.stream/3_or_4 if needed
  # TODO: Implement functions for managing prepared statements if distinct from execute's internal prep is needed

end
