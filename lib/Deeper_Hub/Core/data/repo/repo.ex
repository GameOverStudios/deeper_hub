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
    # O nome do módulo usado aqui para Application.get_env deve ser o novo nome do módulo
    Application.get_env(:deeper_hub, __MODULE__, [])
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
  """
  def execute(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Executando SQL: #{sql_string} com parâmetros: #{inspect(params)}", module: __MODULE__)
    
    # Cria uma query Exqlite
    query = prepare_query(sql_string)
    
    # Tenta executar a query usando o DBConnection
    try do
      case DBConnection.prepare_execute(pool_name(), query, params, opts) do
        {:ok, _query_struct, result} ->
          Logger.debug("Execução bem-sucedida. Resultado: #{inspect(result)}", module: __MODULE__)
          {:ok, result}
        {:error, exception} ->
          Logger.error("Falha na execução. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}", module: __MODULE__)
          {:error, exception}
      end
    rescue
      exception ->
        Logger.error("Exceção ao executar SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}", module: __MODULE__)
        {:error, exception}
    end
  end

  @doc """
  Executa uma consulta SQL esperada para retornar linhas (ex: SELECT).
  Retorna `{:ok, rows_list}` ou `{:error, exception}`.
  """
  def query(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Consultando SQL: #{sql_string} com parâmetros: #{inspect(params)}", module: __MODULE__)
    
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
          Logger.error("Falha na consulta. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}", module: __MODULE__)
          {:error, exception}
      end
    rescue
      exception ->
        Logger.error("Exceção ao consultar SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}", module: __MODULE__)
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
