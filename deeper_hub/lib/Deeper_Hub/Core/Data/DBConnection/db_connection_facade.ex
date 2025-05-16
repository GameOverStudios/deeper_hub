defmodule Deeper_Hub.Core.Data.DBConnection.DBConnectionFacade do
  @moduledoc """
  Fachada para operações de conexão com banco de dados no sistema DeeperHub.
  
  Este módulo fornece uma interface simplificada para operações de banco de dados,
  abstraindo a complexidade da biblioteca DBConnection e permitindo o uso
  consistente em toda a aplicação.
  
  ## Funcionalidades
  
  * 🔄 Interface simplificada para operações de banco de dados
  * 📝 Preparação e execução de consultas
  * 🔒 Suporte a transações com rollback automático
  * 📊 Coleta de métricas de desempenho
  * 🛡️ Tratamento de erros e logging consistente
  
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
  alias Deeper_Hub.Core.Metrics.Helpers, as: MetricsHelpers
  
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
    
    MetricsHelpers.measure("deeper_hub.db_connection.start_link", fn ->
      DBConnectionAdapter.start_link(conn_mod, opts)
    end, %{conn_mod: conn_mod})
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
    
    MetricsHelpers.measure("deeper_hub.db_connection.prepare", fn ->
      DBConnectionAdapter.prepare(conn, query, opts)
    end, %{query: inspect(query)})
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
      params: inspect(params)
    })
    
    MetricsHelpers.measure("deeper_hub.db_connection.execute", fn ->
      DBConnectionAdapter.execute(conn, query, params, opts)
    end, %{
      query: inspect(query),
      params_count: length(List.wrap(params))
    })
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
      params: inspect(params)
    })
    
    MetricsHelpers.measure("deeper_hub.db_connection.prepare_execute", fn ->
      DBConnectionAdapter.prepare_execute(conn, query, params, opts)
    end, %{
      query: inspect(query),
      params_count: length(List.wrap(params))
    })
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
  @spec transaction(DBConnection.conn(), (DBConnection.conn() -> any()), Keyword.t()) ::
          {:ok, any()} | {:error, term()}
  def transaction(conn, fun, opts \\ []) do
    Logger.debug("Iniciando transação", %{
      module: __MODULE__
    })
    
    MetricsHelpers.span("deeper_hub.db_connection.transaction", %{}, fn ->
      DBConnectionAdapter.transaction(conn, fun, opts)
    end)
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
    
    MetricsHelpers.record("deeper_hub.db_connection.rollback", :count, 1, %{
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
    
    MetricsHelpers.measure("deeper_hub.db_connection.run", fn ->
      DBConnectionAdapter.run(conn, fun, opts)
    end)
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
    
    status = DBConnectionAdapter.status(conn, opts)
    
    MetricsHelpers.record("deeper_hub.db_connection.status", :status, status)
    
    status
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
    
    MetricsHelpers.measure("deeper_hub.db_connection.close", fn ->
      DBConnectionAdapter.close(conn, query, opts)
    end, %{query: inspect(query)})
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
