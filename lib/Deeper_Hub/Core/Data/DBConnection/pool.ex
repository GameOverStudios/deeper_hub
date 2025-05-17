defmodule Deeper_Hub.Core.Data.DBConnection.Pool do
  @moduledoc """
  Gerenciador de pool de conexões para o banco de dados.
  
  Este módulo é responsável por gerenciar o pool de conexões com o banco de dados,
  fornecendo funções para executar consultas e transações.
  """
  
  require Logger
  
  alias Deeper_Hub.Core.Data.DBConnection.Connection
  alias Deeper_Hub.Core.Data.DBConnection.Query
  
  @pool_name __MODULE__
  
  @doc """
  Inicia o pool de conexões.
  
  ## Parâmetros
  
    - `opts`: Opções para o pool de conexões
  
  ## Retorno
  
    - `{:ok, pid}` se o pool for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    # Usamos debug ao invés de info para reduzir a duplicação de mensagens importantes
    Logger.debug("Iniciando pool de conexões", %{module: __MODULE__})
    
    # Obtém as configurações de conexão e pool
    alias Deeper_Hub.Core.Data.DBConnection.Config
    conn_config = Config.get_connection_config()
    
    # Configura as opções do pool
    pool_opts = [
      name: @pool_name,
      pool_size: Keyword.get(opts, :pool_size, 10),
      max_overflow: Keyword.get(opts, :max_overflow, 5),
      idle_interval: Keyword.get(opts, :idle_interval, 1000),
      queue_target: Keyword.get(opts, :queue_target, 50),
      queue_interval: Keyword.get(opts, :queue_interval, 1000)
    ]
    
    # Configura as opções da conexão
    conn_opts = [
      database: conn_config.database
    ]
    
    # Inicia o pool de conexões
    # Combinamos as opções de conexão com as opções de pool
    opts = Keyword.merge(conn_opts, pool_opts)
    case DBConnection.start_link(Connection, opts) do
      {:ok, pid} ->
        # Mantemos apenas uma mensagem de sucesso no nível de aplicativo
        Logger.debug("Pool de conexões iniciado com sucesso", %{
          module: __MODULE__,
          database: conn_config.database,
          pool_size: Keyword.get(pool_opts, :pool_size)
        })
        
        {:ok, pid}
      {:error, reason} = error ->
        Logger.error("Falha ao iniciar pool de conexões", %{
          module: __MODULE__,
          database: conn_config.database,
          error: reason
        })
        
        error
    end
  end
  
  @doc """
  Executa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, result}` se a consulta for executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  def query(query, params \\ [], opts \\ []) do
    Logger.debug("Executando consulta", %{
      module: __MODULE__,
      query: query,
      params: params
    })
    
    # Verificamos se a query é uma string e a convertemos para um objeto Query
    query_obj = case query do
      q when is_binary(q) -> Query.new(q)
      _ -> query
    end
    
    # Verificamos se a consulta deve usar cache
    use_cache = Keyword.get(opts, :cache, false)
    cache_key = if use_cache, do: cache_key_for_query(query_obj, params)
    
    if use_cache do
      # Tentamos obter o resultado do cache
      case Deeper_Hub.Core.Cache.get(cache_key) do
        {:ok, nil} ->
          # Cache miss, executamos a consulta normalmente
          Deeper_Hub.Core.Metrics.cache_miss(cache_key)
          execute_and_cache_query(query_obj, params, opts, cache_key)
          
        {:ok, cached_result} ->
          # Cache hit, retornamos o resultado do cache
          Deeper_Hub.Core.Metrics.cache_hit(cache_key)
          {:ok, cached_result}
          
        _error ->
          # Erro ao acessar o cache, executamos a consulta normalmente
          execute_query(query_obj, params, opts)
      end
    else
      # Sem cache, executamos a consulta normalmente
      execute_query(query_obj, params, opts)
    end
  end
  
  # Função auxiliar para executar uma consulta e armazenar o resultado no cache
  defp execute_and_cache_query(query_obj, params, opts, cache_key) do
    # Definimos o TTL do cache a partir das opções ou usamos o padrão
    cache_ttl = Keyword.get(opts, :cache_ttl, :timer.minutes(10))
    
    # Executamos a consulta
    case execute_query(query_obj, params, opts) do
      {:ok, result} = ok_result ->
        # Armazenamos o resultado no cache
        Deeper_Hub.Core.Cache.put(cache_key, result, cache_ttl)
        ok_result
        
      error ->
        # Em caso de erro, não armazenamos no cache
        error
    end
  end
  
  # Função auxiliar para executar uma consulta com métricas
  defp execute_query(query_obj, params, opts) do
    # Iniciamos a medição de desempenho
    query_str = query_obj.statement
    Deeper_Hub.Core.Metrics.start_query(query_str, params)

    try do
      result = case DBConnection.execute(@pool_name, query_obj, params, opts) do 
        {:ok, _query, result} ->
          {:ok, result}
        {:error, %DBConnection.ConnectionError{} = error} ->
          Logger.error("Falha ao executar consulta", %{
            module: __MODULE__,
            query: query_str,
            params: params,
            error: error
          })
          {:error, error}
        {:error, reason} ->
          Logger.error("Falha ao executar consulta", %{
            module: __MODULE__,
            query: query_str,
            params: params,
            error: reason
          })
          {:error, reason}
      end

      # Finalizamos a medição de desempenho
      Deeper_Hub.Core.Metrics.stop_query(query_str, params, result)

      result
    rescue
      e ->
        Logger.error("Exceção ao executar consulta", %{
          module: __MODULE__,
          query: query_str,
          params: params,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        # Finalizamos a medição mesmo em caso de exceção
        Deeper_Hub.Core.Metrics.stop_query(query_str, params, {:error, e})

        {:error, e}
    catch
      kind, reason ->
        # Finalizamos a medição mesmo em caso de exceção
        stacktrace = __STACKTRACE__
        Deeper_Hub.Core.Metrics.stop_query(query_str, params, {:error, reason})  
        :erlang.raise(kind, reason, stacktrace)
    end
  end
  
  @doc """
  Executa uma consulta SQL e retorna o primeiro resultado.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, row}` se a consulta for executada com sucesso e retornar resultados
    - `{:ok, nil}` se a consulta for executada com sucesso mas não retornar resultados
    - `{:error, reason}` em caso de falha
  """
  def query_one(query, params \\ [], opts \\ []) do
    case query(query, params, opts) do
      {:ok, %{rows: [row | _]}} ->
        {:ok, row}
      {:ok, %{rows: []}} ->
        {:ok, nil}
      error ->
        error
    end
  end
  
  @doc """
  Executa uma consulta SQL dentro de uma transação.
  
  ## Parâmetros
  
    - `fun`: Função que recebe a conexão e executa operações dentro da transação
    - `opts`: Opções da transação
  
  ## Retorno
  
    - `{:ok, result}` se a transação for executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  def transaction(fun, opts \\ []) do
    Logger.debug("Iniciando transação", %{module: __MODULE__})
    
    try do
      DBConnection.transaction(@pool_name, fun, opts)
    rescue
      e ->
        Logger.error("Exceção durante transação", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Prepara uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de preparação
  
  ## Retorno
  
    - `{:ok, prepared_query}` se a consulta for preparada com sucesso
    - `{:error, reason}` em caso de falha
  """
  def prepare(query, opts \\ []) do
    Logger.debug("Preparando consulta", %{
      module: __MODULE__,
      query: query
    })
    
    try do
      case DBConnection.prepare(@pool_name, query, opts) do
        {:ok, prepared_query} ->
          {:ok, prepared_query}
        {:error, reason} ->
          Logger.error("Falha ao preparar consulta", %{
            module: __MODULE__,
            query: query,
            error: reason
          })
          
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exceção ao preparar consulta", %{
          module: __MODULE__,
          query: query,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Prepara e executa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, prepared_query, result}` se a consulta for preparada e executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  def prepare_execute(query, params \\ [], opts \\ []) do
    Logger.debug("Preparando e executando consulta", %{
      module: __MODULE__,
      query: query,
      params: params
    })
    
    try do
      case DBConnection.prepare_execute(@pool_name, query, params, opts) do
        {:ok, prepared_query, result} ->
          {:ok, prepared_query, result}
        {:error, reason} ->
          Logger.error("Falha ao preparar e executar consulta", %{
            module: __MODULE__,
            query: query,
            params: params,
            error: reason
          })
          
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exceção ao preparar e executar consulta", %{
          module: __MODULE__,
          query: query,
          params: params,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Cria um stream para uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - Um stream para a consulta
  """
  def stream(query, params \\ [], opts \\ []) do
    Logger.debug("Criando stream para consulta", %{
      module: __MODULE__,
      query: query,
      params: params
    })
    
    # Cria um stream para a consulta
    # Obs: Precisamos obter uma conexão antes de criar o stream
    case DBConnection.run(@pool_name, fn conn ->
      DBConnection.stream(conn, query, params, opts)
    end, opts) do
      {:ok, stream} -> stream
      {:error, _} = error -> error
    end
  end
  
  @doc """
  Verifica o status da conexão.
  
  ## Parâmetros
  
    - `opts`: Opções da verificação
  
  ## Retorno
  
    - `{:ok, status}` com o status da conexão
    - `{:error, reason}` em caso de falha
  """
  def status(opts \\ []) do
    try do
      DBConnection.status(@pool_name, opts)
    rescue
      e ->
        Logger.error("Exceção ao verificar status da conexão", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  # Esta função foi removida pois agora usamos o módulo de configuração
  
  # Gera uma chave de cache para uma consulta SQL
  defp cache_key_for_query(query, params) do
    # Usamos a consulta SQL e os parâmetros para gerar uma chave única
    query_str = query.statement
    params_str = inspect(params)
    
    # Geramos um hash MD5 da consulta e parâmetros para usar como chave
    :crypto.hash(:md5, query_str <> params_str)
    |> Base.encode16()
    |> String.downcase()
  end
end
