defmodule Deeper_Hub.Core.Data.DBConnection.DBConnectionAdapter do
  @moduledoc """
  Adaptador para a biblioteca DBConnection que implementa o comportamento DBConnectionBehaviour.
  
  Este módulo fornece uma implementação completa das operações de conexão com banco de dados
  usando a biblioteca `:db_connection`, permitindo a preparação e execução de consultas,
  transações e gerenciamento de conexões.
  
  ## Funcionalidades
  
  * 🔄 Gerenciamento de pool de conexões
  * 📝 Preparação e execução de consultas
  * 🔒 Suporte a transações com rollback automático
  * 📊 Coleta de métricas de conexão
  * 🛡️ Tratamento de erros de conexão
  
  ## Exemplos
  
  ```elixir
  # Iniciar uma conexão
  {:ok, conn} = DBConnectionAdapter.start_link(MyConnector, [
    database: "my_db",
    username: "user",
    password: "pass",
    hostname: "localhost"
  ])
  
  # Executar uma consulta
  {:ok, result} = DBConnectionAdapter.execute(conn, "SELECT * FROM users", [])
  
  # Executar uma transação
  {:ok, result} = DBConnectionAdapter.transaction(conn, fn conn ->
    {:ok, _} = DBConnectionAdapter.execute(conn, "INSERT INTO users (name) VALUES (?)", ["Alice"])
    {:ok, _} = DBConnectionAdapter.execute(conn, "INSERT INTO logs (action) VALUES (?)", ["user_created"])
    :ok
  end)
  ```
  """
  
  @behaviour Deeper_Hub.Core.Data.DBConnection.DBConnectionBehaviour
  
  alias Deeper_Hub.Core.Logger
  
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
  {:ok, conn} = DBConnectionAdapter.start_link(MyConnector, [
    database: "my_db",
    username: "user",
    password: "pass",
    hostname: "localhost"
  ])
  ```
  """
  @impl true
  @spec start_link(module(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(conn_mod, opts) do
    Logger.debug("Iniciando conexão com o banco de dados", %{
      module: __MODULE__,
      conn_mod: conn_mod,
      opts: sanitize_opts(opts)
    })
    
    # Configurar opções padrão
    default_opts = [
      pool_size: 10,
      idle_interval: 5_000,
      show_sensitive_data_on_connection_error: false
    ]
    
    # Mesclar opções padrão com as fornecidas
    merged_opts = Keyword.merge(default_opts, opts)
    
    # Adicionar telemetry listener para eventos de conexão
    merged_opts = 
      if Keyword.has_key?(merged_opts, :connection_listeners) do
        listeners = Keyword.get(merged_opts, :connection_listeners, [])
        Keyword.put(merged_opts, :connection_listeners, [DBConnection.TelemetryListener | listeners])
      else
        Keyword.put(merged_opts, :connection_listeners, [DBConnection.TelemetryListener])
      end
    
    # Iniciar a conexão
    try do
      result = DBConnection.start_link(conn_mod, merged_opts)
      
      case result do
        {:ok, pid} ->
          Logger.info("Conexão com o banco de dados iniciada com sucesso", %{
            module: __MODULE__,
            conn_mod: conn_mod,
            pid: inspect(pid)
          })
          
          result
          
        {:error, reason} ->
          Logger.error("Erro ao iniciar conexão com o banco de dados", %{
            module: __MODULE__,
            conn_mod: conn_mod,
            reason: inspect(reason)
          })
          
          result
      end
    rescue
      e ->
        Logger.error("Exceção ao iniciar conexão com o banco de dados", %{
          module: __MODULE__,
          conn_mod: conn_mod,
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        {:error, e}
    end
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
  {:ok, prepared_query} = DBConnectionAdapter.prepare(conn, "SELECT * FROM users WHERE id = ?", [])
  ```
  """
  @impl true
  @spec prepare(DBConnection.conn(), term(), Keyword.t()) ::
          {:ok, term()} | {:error, Exception.t()}
  def prepare(conn, query, opts \\ []) do
    Logger.debug("Preparando consulta", %{
      module: __MODULE__,
      query: inspect(query)
    })
    
    try do
      result = DBConnection.prepare(conn, query, opts)
      
      case result do
        {:ok, _prepared_query} ->
          Logger.debug("Consulta preparada com sucesso", %{
            module: __MODULE__,
            query: inspect(query)
          })
          
          result
          
        {:error, exception} ->
          Logger.error("Erro ao preparar consulta", %{
            module: __MODULE__,
            query: inspect(query),
            exception: inspect(exception)
          })
          
          result
      end
    rescue
      e ->
        Logger.error("Exceção ao preparar consulta", %{
          module: __MODULE__,
          query: inspect(query),
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        {:error, e}
    end
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
  {:ok, result} = DBConnectionAdapter.execute(conn, prepared_query, [1])
  ```
  """
  @impl true
  @spec execute(DBConnection.conn(), term(), term(), Keyword.t()) ::
          {:ok, term()} | {:error, Exception.t()}
  def execute(conn, query, params, opts \\ []) do
    Logger.debug("Executando consulta", %{
      module: __MODULE__,
      query: inspect(query),
      params: inspect(params)
    })
    
    # Registrar métricas de início da execução
    start_time = System.monotonic_time()
    
    try do
      result = DBConnection.execute(conn, query, params, opts)
      
      # Registrar métricas de fim da execução
      end_time = System.monotonic_time()
      duration = end_time - start_time
      
      # Emitir evento de telemetria
      :telemetry.execute(
        [:deeper_hub, :db_connection, :execute],
        %{duration: duration},
        %{query: inspect(query), params: inspect(params)}
      )
      
      case result do
        {:ok, _query_result} ->
          Logger.debug("Consulta executada com sucesso", %{
            module: __MODULE__,
            query: inspect(query),
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
          
        {:error, exception} ->
          Logger.error("Erro ao executar consulta", %{
            module: __MODULE__,
            query: inspect(query),
            params: inspect(params),
            exception: inspect(exception),
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
      end
    rescue
      e ->
        # Registrar métricas de fim da execução em caso de exceção
        end_time = System.monotonic_time()
        duration = end_time - start_time
        
        Logger.error("Exceção ao executar consulta", %{
          module: __MODULE__,
          query: inspect(query),
          params: inspect(params),
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__),
          duration_us: System.convert_time_unit(duration, :native, :microsecond)
        })
        
        {:error, e}
    end
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
  {:ok, prepared_query, result} = DBConnectionAdapter.prepare_execute(
    conn, 
    "SELECT * FROM users WHERE id = ?", 
    [1]
  )
  ```
  """
  @impl true
  @spec prepare_execute(DBConnection.conn(), term(), term(), Keyword.t()) ::
          {:ok, term(), term()} | {:error, Exception.t()}
  def prepare_execute(conn, query, params, opts \\ []) do
    Logger.debug("Preparando e executando consulta", %{
      module: __MODULE__,
      query: inspect(query),
      params: inspect(params)
    })
    
    # Registrar métricas de início da operação
    start_time = System.monotonic_time()
    
    try do
      result = DBConnection.prepare_execute(conn, query, params, opts)
      
      # Registrar métricas de fim da operação
      end_time = System.monotonic_time()
      duration = end_time - start_time
      
      # Emitir evento de telemetria
      :telemetry.execute(
        [:deeper_hub, :db_connection, :prepare_execute],
        %{duration: duration},
        %{query: inspect(query), params: inspect(params)}
      )
      
      case result do
        {:ok, _prepared_query, _query_result} ->
          Logger.debug("Consulta preparada e executada com sucesso", %{
            module: __MODULE__,
            query: inspect(query),
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
          
        {:error, exception} ->
          Logger.error("Erro ao preparar e executar consulta", %{
            module: __MODULE__,
            query: inspect(query),
            params: inspect(params),
            exception: inspect(exception),
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
      end
    rescue
      e ->
        # Registrar métricas de fim da operação em caso de exceção
        end_time = System.monotonic_time()
        duration = end_time - start_time
        
        Logger.error("Exceção ao preparar e executar consulta", %{
          module: __MODULE__,
          query: inspect(query),
          params: inspect(params),
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__),
          duration_us: System.convert_time_unit(duration, :native, :microsecond)
        })
        
        {:error, e}
    end
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
  {:ok, result} = DBConnectionAdapter.transaction(conn, fn conn ->
    {:ok, _} = DBConnectionAdapter.execute(conn, "INSERT INTO users (name) VALUES (?)", ["Alice"])
    {:ok, _} = DBConnectionAdapter.execute(conn, "INSERT INTO logs (action) VALUES (?)", ["user_created"])
    :ok
  end)
  ```
  """
  @impl true
  @spec transaction(DBConnection.conn(), (DBConnection.conn() -> any()), Keyword.t()) ::
          {:ok, any()} | {:error, term()}
  def transaction(conn, fun, opts \\ []) do
    Logger.debug("Iniciando transação", %{
      module: __MODULE__
    })
    
    # Registrar métricas de início da transação
    start_time = System.monotonic_time()
    
    try do
      result = DBConnection.transaction(conn, fun, opts)
      
      # Registrar métricas de fim da transação
      end_time = System.monotonic_time()
      duration = end_time - start_time
      
      # Emitir evento de telemetria
      :telemetry.execute(
        [:deeper_hub, :db_connection, :transaction],
        %{duration: duration},
        %{status: elem(result, 0)}
      )
      
      case result do
        {:ok, _value} ->
          Logger.debug("Transação concluída com sucesso", %{
            module: __MODULE__,
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
          
        {:error, reason} ->
          Logger.error("Erro na transação", %{
            module: __MODULE__,
            reason: inspect(reason),
            duration_us: System.convert_time_unit(duration, :native, :microsecond)
          })
          
          result
      end
    rescue
      e ->
        # Registrar métricas de fim da transação em caso de exceção
        end_time = System.monotonic_time()
        duration = end_time - start_time
        
        Logger.error("Exceção na transação", %{
          module: __MODULE__,
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__),
          duration_us: System.convert_time_unit(duration, :native, :microsecond)
        })
        
        {:error, e}
    end
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
  DBConnectionAdapter.transaction(conn, fn conn ->
    case check_condition() do
      :ok -> :ok
      :error -> DBConnectionAdapter.rollback(conn, :validation_failed)
    end
  end)
  ```
  """
  @impl true
  @spec rollback(DBConnection.conn(), term()) :: no_return()
  def rollback(conn, reason) do
    Logger.debug("Desfazendo transação", %{
      module: __MODULE__,
      reason: inspect(reason)
    })
    
    # Emitir evento de telemetria
    :telemetry.execute(
      [:deeper_hub, :db_connection, :rollback],
      %{count: 1},
      %{reason: inspect(reason)}
    )
    
    try do
      DBConnection.rollback(conn, reason)
    rescue
      e ->
        Logger.error("Exceção ao desfazer transação", %{
          module: __MODULE__,
          reason: inspect(reason),
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        reraise e, __STACKTRACE__
    end
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
  result = DBConnectionAdapter.run(conn, fn conn ->
    # Operações com a conexão
    :ok
  end)
  ```
  """
  @impl true
  @spec run(DBConnection.conn(), (DBConnection.conn() -> any()), Keyword.t()) :: any()
  def run(conn, fun, opts \\ []) do
    Logger.debug("Executando função com conexão", %{
      module: __MODULE__
    })
    
    # Registrar métricas de início da execução
    start_time = System.monotonic_time()
    
    try do
      result = DBConnection.run(conn, fun, opts)
      
      # Registrar métricas de fim da execução
      end_time = System.monotonic_time()
      duration = end_time - start_time
      
      # Emitir evento de telemetria
      :telemetry.execute(
        [:deeper_hub, :db_connection, :run],
        %{duration: duration},
        %{}
      )
      
      Logger.debug("Função executada com sucesso", %{
        module: __MODULE__,
        duration_us: System.convert_time_unit(duration, :native, :microsecond)
      })
      
      result
    rescue
      e ->
        # Registrar métricas de fim da execução em caso de exceção
        end_time = System.monotonic_time()
        duration = end_time - start_time
        
        Logger.error("Exceção ao executar função com conexão", %{
          module: __MODULE__,
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__),
          duration_us: System.convert_time_unit(duration, :native, :microsecond)
        })
        
        reraise e, __STACKTRACE__
    end
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
  status = DBConnectionAdapter.status(conn)
  ```
  """
  @impl true
  @spec status(DBConnection.conn(), Keyword.t()) :: :idle | :busy | :closed
  def status(conn, opts \\ []) do
    Logger.debug("Obtendo status da conexão", %{
      module: __MODULE__
    })
    
    try do
      status = DBConnection.status(conn, opts)
      
      Logger.debug("Status da conexão obtido", %{
        module: __MODULE__,
        status: status
      })
      
      status
    rescue
      e ->
        Logger.error("Exceção ao obter status da conexão", %{
          module: __MODULE__,
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        :closed
    end
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
  :ok = DBConnectionAdapter.close(conn, prepared_query)
  ```
  """
  @impl true
  @spec close(DBConnection.conn(), term(), Keyword.t()) :: :ok | {:error, Exception.t()}
  def close(conn, query, opts \\ []) do
    Logger.debug("Fechando consulta preparada", %{
      module: __MODULE__,
      query: inspect(query)
    })
    
    try do
      result = DBConnection.close(conn, query, opts)
      
      case result do
        :ok ->
          Logger.debug("Consulta preparada fechada com sucesso", %{
            module: __MODULE__,
            query: inspect(query)
          })
          
          result
          
        {:error, exception} ->
          Logger.error("Erro ao fechar consulta preparada", %{
            module: __MODULE__,
            query: inspect(query),
            exception: inspect(exception)
          })
          
          result
      end
    rescue
      e ->
        Logger.error("Exceção ao fechar consulta preparada", %{
          module: __MODULE__,
          query: inspect(query),
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        {:error, e}
    end
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
  metrics = DBConnectionAdapter.get_connection_metrics(conn)
  ```
  """
  @impl true
  @spec get_connection_metrics(DBConnection.conn(), Keyword.t()) :: map()
  def get_connection_metrics(conn, opts \\ []) do
    Logger.debug("Obtendo métricas de conexão", %{
      module: __MODULE__
    })
    
    try do
      metrics = DBConnection.get_connection_metrics(conn, opts)
      
      Logger.debug("Métricas de conexão obtidas", %{
        module: __MODULE__,
        metrics: inspect(metrics)
      })
      
      metrics
    rescue
      e ->
        Logger.error("Exceção ao obter métricas de conexão", %{
          module: __MODULE__,
          exception: inspect(e),
          stacktrace: inspect(__STACKTRACE__)
        })
        
        %{error: inspect(e)}
    end
  end
  
  # Funções privadas
  
  # Remove informações sensíveis das opções de conexão para logging
  defp sanitize_opts(opts) do
    sensitive_keys = [:password, :pass, :key, :secret, :token]
    
    Enum.reduce(opts, [], fn
      {key, value}, acc ->
        if key in sensitive_keys do
          [{key, "[REDACTED]"} | acc]
        else
          [{key, value} | acc]
        end
    end)
    |> Enum.reverse()
  end
end
