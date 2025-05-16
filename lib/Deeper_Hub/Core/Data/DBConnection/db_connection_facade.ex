defmodule Deeper_Hub.Core.Data.DBConnection.DBConnectionFacade do
  @moduledoc """
  Fachada para operações de conexão com banco de dados no sistema Deeper_Hub.

  Este módulo fornece uma interface simplificada para operações de banco de dados,
  abstraindo a complexidade da biblioteca DBConnection e permitindo o uso
  consistente em toda a aplicação.

  ## Funcionalidades

  * 🔄 Interface simplificada para operações de banco de dados
  * 📝 Preparação e execução de consultas
  * 🔒 Suporte a transações com rollback automático
  * 🛡️ Tratamento de erros e logging consistente
  * 📊 Telemetria para monitoramento de desempenho

  ## Exemplos

  ```elixir
  # Iniciar uma conexão
  {:ok, conn} = DBConnectionFacade.start_link(MyConnector, [
    database: "my_db",
    username: "user",
    password: "pass",
    hostname: "localhost"
  ])

  # Executar uma consulta
  {:ok, result} = DBConnectionFacade.execute(conn, "SELECT * FROM users", [])

  # Executar uma transação
  {:ok, result} = DBConnectionFacade.transaction(conn, fn conn ->
    {:ok, _} = DBConnectionFacade.execute(conn, "INSERT INTO users (name) VALUES (?)", ["Alice"])
    {:ok, _} = DBConnectionFacade.execute(conn, "INSERT INTO logs (action) VALUES (?)", ["user_created"])
    :ok
  end)
  ```
  """

  alias Deeper_Hub.Core.Data.DBConnection.DBConnectionAdapter
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.EventBus.EventDefinitions
  alias Deeper_Hub.Core.Resilience.CircuitBreaker

  @doc """
  Inicia uma conexão com o banco de dados.

  ## Parâmetros

    * `conn_mod` - Módulo de conexão
    * `opts` - Opções de conexão

  ## Retorno

    * `{:ok, pid}` - Conexão iniciada com sucesso
    * `{:error, term()}` - Erro ao iniciar a conexão

  ## Exemplos

  ```elixir
  {:ok, conn} = DBConnectionFacade.start_link(MyConnector, [
    database: "my_db",
    username: "user",
    password: "pass",
    hostname: "localhost"
  ])
  ```
  """
  @spec start_link(module(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(conn_mod, opts) do
    Logger.info("Iniciando conexão com o banco de dados", %{
      module: __MODULE__,
      conn_mod: conn_mod
    })

    DBConnectionAdapter.start_link(conn_mod, opts)
  end

  @doc """
  Prepara uma consulta para execução.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser preparada
    * `opts` - Opções de preparação

  ## Retorno

    * `{:ok, prepared_query}` - Consulta preparada com sucesso
    * `{:error, exception}` - Erro ao preparar a consulta

  ## Exemplos

  ```elixir
  {:ok, prepared_query} = DBConnectionFacade.prepare(conn, "SELECT * FROM users WHERE id = ?", [])
  ```
  """
  @spec prepare(DBConnection.conn(), term(), Keyword.t()) ::
          {:ok, term()} | {:error, Exception.t()}
  def prepare(conn, query, opts \\ []) do
    Logger.debug("Preparando consulta", %{
      module: __MODULE__,
      query: inspect(query)
    })

    DBConnectionAdapter.prepare(conn, query, opts)
  end

  @doc """
  Executa uma consulta preparada.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta preparada
    * `params` - Parâmetros da consulta
    * `opts` - Opções de execução

  ## Retorno

    * `{:ok, result}` - Consulta executada com sucesso
    * `{:error, exception}` - Erro ao executar a consulta

  ## Exemplos

  ```elixir
  {:ok, result} = DBConnectionFacade.execute(conn, prepared_query, [1])

  # Ou diretamente com uma string SQL
  {:ok, result} = DBConnectionFacade.execute(conn, "SELECT * FROM users WHERE id = ?", [1])
  ```
  """
  @spec execute(DBConnection.conn(), term(), term(), Keyword.t()) ::
          {:ok, term()} | {:error, Exception.t()}
  def execute(conn, query, params, opts \\ []) do
    Logger.debug("Executando consulta", %{
      module: __MODULE__,
      query: inspect(query),
      params_count: length(params)
    })

    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()

    # Extrai informações para telemetria
    operation = extract_operation(query)

    table = extract_table(query)
    
    # Executa a consulta com proteção de circuit breaker
    result = CircuitBreaker.call(
      :db_execute,
      fn -> DBConnectionAdapter.execute(conn, query, params, opts) end,
      [],
      threshold: 5,
      timeout_sec: 30,
      match_error: fn
        {:error, _} -> true
        _ -> false
      end
    )

    # Cálculo da duração para telemetria
    end_time = System.monotonic_time()
    duration = end_time - start_time

    # Emite evento de telemetria para consulta
    case result do
      {:ok, result} ->
        # Tenta obter o número de linhas afetadas/retornadas
        rows = get_result_rows(result)

        TelemetryEvents.execute_db_query(
          %{duration: duration, count: 1, rows: rows},
          %{operation: operation, table: table, module: __MODULE__, params_count: length(params), status: :success}
        )

        # Emite evento para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_query(),
          %{duration: duration, rows: rows, status: :success, query: query},
          source: "#{__MODULE__}"
        )

      {:error, exception} ->
        TelemetryEvents.execute_db_query(
          %{duration: duration, count: 1, rows: 0},
          %{operation: operation, table: table, module: __MODULE__, params_count: length(params), status: :error}
        )

        # Emite evento de erro para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_error(),
          %{duration: duration, status: :error, query: query, error: exception},
          source: "#{__MODULE__}"
        )
    end

    result
  end

  @doc """
  Prepara e executa uma consulta em uma única operação.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser preparada e executada
    * `params` - Parâmetros da consulta
    * `opts` - Opções de preparação e execução

  ## Retorno

    * `{:ok, prepared_query, result}` - Consulta preparada e executada com sucesso
    * `{:error, exception}` - Erro ao preparar ou executar a consulta

  ## Exemplos

  ```elixir
  {:ok, prepared_query, result} = DBConnectionFacade.prepare_execute(
    conn,
    "SELECT * FROM users WHERE id = ?",
    [1]
  )
  ```
  """
  @spec prepare_execute(DBConnection.conn(), term(), term(), Keyword.t()) ::
          {:ok, term(), term()} | {:error, Exception.t()}
  def prepare_execute(conn, query, params, opts \\ []) do
    Logger.debug("Preparando e executando consulta", %{
      module: __MODULE__,
      query: inspect(query),
      params_count: length(params)
    })

    # Executa a preparação e execução com proteção de circuit breaker
    CircuitBreaker.call(
      :db_prepare_execute,
      fn -> DBConnectionAdapter.prepare_execute(conn, query, params, opts) end,
      [],
      threshold: 5,
      timeout_sec: 30,
      match_error: fn
        {:error, _} -> true
        _ -> false
      end
    )
  end

  @doc """
  Executa uma função dentro de uma transação.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `fun` - Função a ser executada dentro da transação
    * `opts` - Opções da transação

  ## Retorno

    * `{:ok, result}` - Transação concluída com sucesso
    * `{:error, reason}` - Erro na transação

  ## Exemplos

  ```elixir
  {:ok, result} = DBConnectionFacade.transaction(conn, fn conn ->
    {:ok, _} = DBConnectionFacade.execute(conn, "INSERT INTO users (name) VALUES (?)", ["Alice"])
    {:ok, _} = DBConnectionFacade.execute(conn, "INSERT INTO logs (action) VALUES (?)", ["user_created"])
    :ok
  end)
  ```
  """
  @spec transaction(DBConnection.conn(), (DBConnection.conn() -> result), Keyword.t()) ::
          {:ok, result} | {:error, any()}
        when result: var
  def transaction(conn, fun, opts \\ []) do
    Logger.debug("Iniciando transação", %{
      module: __MODULE__
    })

    # Início da medição de tempo para telemetria
    start_time = System.monotonic_time()

    # Executa a transação com proteção de circuit breaker
    result = CircuitBreaker.call(
      :db_transaction,
      fn -> DBConnectionAdapter.transaction(conn, fun, opts) end,
      [],
      threshold: 3,
      timeout_sec: 60,
      match_error: fn
        {:error, _} -> true
        _ -> false
      end
    )

    # Cálculo da duração para telemetria
    end_time = System.monotonic_time()
    duration = end_time - start_time

    # Emite evento de telemetria para transação
    case result do
      {:ok, _value} ->
        TelemetryEvents.execute_db_transaction(
          %{duration: duration, count: 1},
          %{status: :success, module: __MODULE__}
        )

        # Emite evento para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_transaction(),
          %{duration: duration, status: :success},
          source: "#{__MODULE__}"
        )

      {:error, reason} ->
        TelemetryEvents.execute_db_transaction(
          %{duration: duration, count: 1},
          %{status: :error, module: __MODULE__, reason: inspect(reason)}
        )

        # Emite evento de erro para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_error(),
          %{duration: duration, status: :error, error: reason},
          source: "#{__MODULE__}"
        )
    end

    result
  end

  @doc """
  Desfaz uma transação.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `reason` - Motivo do rollback

  ## Retorno

    * no_return

  ## Exemplos

  ```elixir
  DBConnectionFacade.transaction(conn, fn conn ->
    case check_condition() do
      :ok -> :ok
      :error -> DBConnectionFacade.rollback(conn, :validation_failed)
    end
  end)
  ```
  """
  @spec rollback(DBConnection.conn(), term()) :: no_return()
  def rollback(conn, reason) do
    Logger.debug("Desfazendo transação", %{
      module: __MODULE__,
      reason: inspect(reason)
    })

    DBConnectionAdapter.rollback(conn, reason)
  end

  @doc """
  Executa uma função com uma conexão.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `fun` - Função a ser executada
    * `opts` - Opções de execução

  ## Retorno

    * `result` - Resultado da função

  ## Exemplos

  ```elixir
  result = DBConnectionFacade.run(conn, fn conn ->
    # Operações com a conexão
    :ok
  end)
  ```
  """
  @spec run(DBConnection.conn(), (DBConnection.conn() -> any()), Keyword.t()) :: any()
  def run(conn, fun, opts \\ []) do
    Logger.debug("Executando função com conexão", %{
      module: __MODULE__
    })

    DBConnectionAdapter.run(conn, fun, opts)
  end

  @doc """
  Obtém o status da conexão.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `opts` - Opções

  ## Retorno

    * `:idle` | `:busy` | `:closed` - Status da conexão

  ## Exemplos

  ```elixir
  status = DBConnectionFacade.status(conn)
  ```
  """
  @spec status(DBConnection.conn(), Keyword.t()) :: :idle | :busy | :closed
  def status(conn, opts \\ []) do
    Logger.debug("Obtendo status da conexão", %{
      module: __MODULE__
    })

    DBConnectionAdapter.status(conn, opts)
  end

  @doc """
  Fecha uma consulta preparada.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta preparada
    * `opts` - Opções

  ## Retorno

    * `:ok` - Consulta fechada com sucesso
    * `{:error, exception}` - Erro ao fechar a consulta

  ## Exemplos

  ```elixir
  :ok = DBConnectionFacade.close(conn, prepared_query)
  ```
  """
  @spec close(DBConnection.conn(), term(), Keyword.t()) :: :ok | {:error, Exception.t()}
  def close(conn, query, opts \\ []) do
    Logger.debug("Fechando consulta preparada", %{
      module: __MODULE__,
      query: inspect(query)
    })

    DBConnectionAdapter.close(conn, query, opts)
  end

  @doc """
  Obtém métricas de conexão.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `opts` - Opções

  ## Retorno

    * `map()` - Métricas da conexão

  ## Exemplos

  ```elixir
  metrics = DBConnectionFacade.get_connection_metrics(conn)
  ```
  """
  @spec get_connection_metrics(DBConnection.conn(), Keyword.t()) :: map()
  def get_connection_metrics(conn, opts \\ []) do
    Logger.debug("Obtendo métricas de conexão", %{
      module: __MODULE__
    })

    DBConnectionAdapter.get_connection_metrics(conn, opts)
  end

  @doc """
  Executa uma consulta e mapeia o resultado para uma estrutura específica.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser executada
    * `params` - Parâmetros da consulta
    * `mapper` - Função para mapear o resultado para uma estrutura
    * `opts` - Opções de execução

  ## Retorno

    * `{:ok, mapped_result}` - Consulta executada com sucesso e resultado mapeado
    * `{:error, exception}` - Erro ao executar a consulta

  ## Exemplos

  ```elixir
  {:ok, users} = DBConnectionFacade.query_map(conn, "SELECT * FROM users", [], fn row ->
    %User{id: row.id, name: row.name, email: row.email}
  end)
  ```
  """
  @spec query_map(DBConnection.conn(), term(), term(), (term() -> term()), Keyword.t()) ::
          {:ok, [term()]} | {:error, Exception.t()}
  def query_map(conn, query, params, mapper, opts \\ []) when is_function(mapper, 1) do
    Logger.debug("Executando consulta com mapeamento", %{
      module: __MODULE__,
      query: inspect(query),
      params: inspect(params)
    })

    case execute(conn, query, params, opts) do
      {:ok, result} ->
        try do
          mapped = map_result(result, mapper)
          {:ok, mapped}
        rescue
          e ->
            Logger.error("Erro ao mapear resultado da consulta", %{
              module: __MODULE__,
              query: inspect(query),
              exception: inspect(e),
              stacktrace: inspect(__STACKTRACE__)
            })

            {:error, e}
        end

      {:error, _} = error ->
        error
    end
  end

  # Funções auxiliares para telemetria
  
  # Extrai a operação (SELECT, INSERT, UPDATE, DELETE) de uma consulta SQL
  defp extract_operation(query) when is_binary(query) do
    query
    |> String.trim()
    |> String.split(" ", parts: 2)
    |> List.first()
    |> String.upcase()
    |> case do
      "SELECT" -> :select
      "INSERT" -> :insert
      "UPDATE" -> :update
      "DELETE" -> :delete
      "CREATE" -> :create
      "ALTER" -> :alter
      "DROP" -> :drop
      _ -> :unknown
    end
  end
  defp extract_operation(_), do: :unknown
  
  # Extrai o nome da tabela de uma consulta SQL (tentativa simples)
  defp extract_table(query) when is_binary(query) do
    query
    |> String.trim()
    |> String.upcase()
    |> extract_table_from_operation()
  end
  defp extract_table(_), do: :unknown
  
  defp extract_table_from_operation(<<"SELECT ", rest::binary>>) do
    rest
    |> String.split("FROM ", parts: 2)
    |> case do
      [_, table_part | _] -> 
        table_part
        |> String.split(" ", parts: 2) 
        |> List.first()
        |> String.trim()
      _ -> :unknown
    end
  end
  defp extract_table_from_operation(<<"INSERT INTO ", rest::binary>>) do
    rest
    |> String.split(" ", parts: 2)
    |> List.first()
    |> String.trim()
  end
  defp extract_table_from_operation(<<"UPDATE ", rest::binary>>) do
    rest
    |> String.split(" ", parts: 2)
    |> List.first()
    |> String.trim()
  end
  defp extract_table_from_operation(<<"DELETE FROM ", rest::binary>>) do
    rest
    |> String.split(" ", parts: 2)
    |> List.first()
    |> String.trim()
  end
  defp extract_table_from_operation(_), do: :unknown
  
  # Tenta obter o número de linhas afetadas/retornadas do resultado
  defp get_result_rows(result) do
    cond do
      is_list(result) -> length(result)
      is_map(result) && Map.has_key?(result, :num_rows) -> Map.get(result, :num_rows)
      is_map(result) && Map.has_key?(result, :rows) -> length(Map.get(result, :rows))
      is_map(result) && Map.has_key?(result, :count) -> Map.get(result, :count)
      true -> 0
    end
  end

  @doc """
  Executa uma consulta dentro de uma transação e mapeia o resultado para uma estrutura específica.

  ## Parâmetros

    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser executada
    * `params` - Parâmetros da consulta
    * `mapper` - Função para mapear o resultado para uma estrutura
    * `opts` - Opções de execução

  ## Retorno

    * `{:ok, mapped_result}` - Consulta executada com sucesso e resultado mapeado
    * `{:error, reason}` - Erro ao executar a consulta ou na transação

  ## Exemplos

  ```elixir
  {:ok, users} = DBConnectionFacade.transaction_query_map(conn, "SELECT * FROM users", [], fn row ->
    %User{id: row.id, name: row.name, email: row.email}
  end)
  ```
  """
  @spec transaction_query_map(
          DBConnection.conn(),
          term(),
          term(),
          (term() -> term()),
          Keyword.t()
        ) ::
          {:ok, [term()]} | {:error, term()}
  def transaction_query_map(conn, query, params, mapper, opts \\ []) when is_function(mapper, 1) do
    Logger.debug("Executando consulta com mapeamento em transação", %{
      module: __MODULE__,
      query: inspect(query),
      params: inspect(params)
    })

    transaction(conn, fn conn ->
      case query_map(conn, query, params, mapper, opts) do
        {:ok, mapped} -> mapped
        {:error, reason} -> rollback(conn, reason)
      end
    end)
  end

  # Funções privadas

  # Mapeia o resultado de uma consulta usando a função mapper
  defp map_result(result, mapper) do
    # Esta implementação é genérica e pode precisar ser adaptada
    # dependendo do formato do resultado retornado pelo driver de banco de dados
    cond do
      is_list(result) ->
        Enum.map(result, mapper)

      is_map(result) and Map.has_key?(result, :rows) ->
        Enum.map(result.rows, mapper)

      true ->
        mapper.(result)
    end
  end
end
