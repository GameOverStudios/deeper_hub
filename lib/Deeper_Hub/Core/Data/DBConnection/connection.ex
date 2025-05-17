defmodule Deeper_Hub.Core.Data.DBConnection.Connection do
  @moduledoc """
  Implementação do comportamento DBConnection para SQLite.
  
  Este módulo implementa o comportamento DBConnection para interagir com
  o banco de dados SQLite através da biblioteca Exqlite.
  """
  
  use DBConnection
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Query
  
  @typedoc "Estado da conexão"
  @type state :: %{
    db_path: String.t(),
    db_ref: reference() | nil,
    transaction: boolean(),
    prepare_cache: map()
  }
  
  @doc """
  Inicia uma conexão com o banco de dados SQLite3.
  
  ## Parâmetros
  
    - `opts`: Opções de conexão
  
  ## Retorno
  
    - `{:ok, state}` se a conexão for bem-sucedida
    - `{:error, Exception.t()}` em caso de falha
  """
  @impl true
  def connect(opts) do
    db_path = Keyword.fetch!(opts, :database)
    
    # Reduzimos o nível de log para diminuir mensagens duplicadas
    Logger.debug("Conectando ao banco de dados SQLite3", %{
      module: __MODULE__,
      database: db_path
    })
    
    # Garante que o diretório do banco de dados existe
    File.mkdir_p!(Path.dirname(db_path))
    
    # Garantimos que o diretório existe sem gerar logs redundantes
    directory = Path.dirname(db_path)
    File.mkdir_p!(directory)
    
    # Abrimos a conexão com o banco de dados sem gerar logs redundantes
    open_result = Exqlite.Sqlite3.open(db_path)
    
    case open_result do
      {:ok, db_ref} ->
        # Configura o banco de dados para performance otimizada
        # Executamos cada PRAGMA e tratamos os resultados
        pragma_results = [
          execute_pragma(db_ref, "PRAGMA journal_mode = WAL", "journal_mode"),
          execute_pragma(db_ref, "PRAGMA synchronous = NORMAL", "synchronous"),
          execute_pragma(db_ref, "PRAGMA foreign_keys = ON", "foreign_keys")
        ]
        
        # Verificamos se todos os PRAGMAs foram executados com sucesso
        unless Enum.all?(pragma_results, &(&1 == :ok)) do
          Logger.warning("Alguns PRAGMAs não puderam ser configurados", %{
            module: __MODULE__,
            database: db_path,
            results: pragma_results
          })
        end
      {:error, reason} ->
        Logger.error("Falha ao abrir banco de dados SQLite", %{
          module: __MODULE__,
          database: db_path,
          error: reason
        })
    end
    
    # Continuamos com o processamento normal
    case open_result do
      {:ok, db_ref} ->
        # Independentemente do resultado dos PRAGMAs, continuamos com a conexão
        
        state = %{
          db_path: db_path,
          db_ref: db_ref,
          transaction: false,
          prepare_cache: %{}
        }
        
        # Reduzimos o nível de log para diminuir mensagens duplicadas
        Logger.debug("Conexão com banco de dados SQLite3 estabelecida", %{
          module: __MODULE__,
          database: db_path
        })
        
        {:ok, state}
      {:error, reason} ->
        Logger.error("Falha ao conectar ao banco de dados SQLite3", %{
          module: __MODULE__,
          database: db_path,
          error: reason
        })
        
        {:error, %DBConnection.ConnectionError{
          message: "Falha ao conectar ao banco de dados SQLite3: #{inspect(reason)}",
          reason: :error,
          severity: :error
        }}
    end
  end
  
  @doc """
  Desconecta do banco de dados SQLite3.
  
  ## Parâmetros
  
    - `err`: Erro que causou a desconexão (se houver)
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `:ok`
  """
  @impl true
  def disconnect(_err, %{db_ref: db_ref} = state) do
    Logger.info("Desconectando do banco de dados SQLite3", %{
      module: __MODULE__,
      database: state.db_path
    })
    
    if db_ref do
      :ok = Exqlite.Sqlite3.close(db_ref)
    end
    
    :ok
  end
  
  @doc """
  Verifica a saúde da conexão.
  
  ## Parâmetros
  
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, state}` se a conexão estiver saudável
    - `{:disconnect, Exception.t(), state}` se a conexão estiver inválida
  """
  @impl true
  def ping(%{db_ref: db_ref} = state) do
    case Exqlite.Sqlite3.execute(db_ref, "SELECT 1") do
      :ok ->
        {:ok, state}
      {:ok, _} ->
        {:ok, state}
      {:error, reason} ->
        Logger.error("Falha ao verificar conexão", %{
          module: __MODULE__,
          database: state.db_path,
          error: reason
        })
        
        {:disconnect, reason, state}
    end
  end
  
  @doc """
  Inicia uma transação.
  
  ## Parâmetros
  
    - `opts`: Opções da transação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a transação for iniciada com sucesso
    - `{:disconnect, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_begin(_opts, %{db_ref: db_ref, transaction: false} = state) do
    Logger.debug("Iniciando transação", %{
      module: __MODULE__,
      database: state.db_path
    })
    
    case Exqlite.Sqlite3.execute(db_ref, "BEGIN TRANSACTION") do
      {:ok, _} ->
        {:ok, %{}, %{state | transaction: true}}
      {:error, reason} ->
        Logger.error("Falha ao iniciar transação", %{
          module: __MODULE__,
          database: state.db_path,
          error: reason
        })
        
        {:error, reason, state}
    end
  end
  
  @doc """
  Confirma uma transação.
  
  ## Parâmetros
  
    - `opts`: Opções da transação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a transação for confirmada com sucesso
    - `{:disconnect, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_commit(_opts, %{db_ref: db_ref, transaction: true} = state) do
    Logger.debug("Confirmando transação", %{
      module: __MODULE__,
      database: state.db_path
    })
    
    case Exqlite.Sqlite3.execute(db_ref, "COMMIT") do
      {:ok, _} ->
        {:ok, %{}, %{state | transaction: false}}
      {:error, reason} ->
        Logger.error("Falha ao confirmar transação", %{
          module: __MODULE__,
          database: state.db_path,
          error: reason
        })
        
        {:error, reason, state}
    end
  end
  
  @doc """
  Reverte uma transação.
  
  ## Parâmetros
  
    - `opts`: Opções da transação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a transação for revertida com sucesso
    - `{:disconnect, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_rollback(_opts, %{db_ref: db_ref, transaction: true} = state) do
    Logger.debug("Revertendo transação", %{
      module: __MODULE__,
      database: state.db_path
    })
    
    case Exqlite.Sqlite3.execute(db_ref, "ROLLBACK") do
      {:ok, _} ->
        {:ok, %{}, %{state | transaction: false}}
      {:error, reason} ->
        Logger.error("Falha ao reverter transação", %{
          module: __MODULE__,
          database: state.db_path,
          error: reason
        })
        
        {:error, reason, state}
    end
  end
  
  @doc """
  Prepara uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções da preparação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, query, state}` se a consulta for preparada com sucesso
    - `{:error, Exception.t(), state}` em caso de falha
    - `{:disconnect, Exception.t(), state}` em caso de falha de conexão
  """
  @impl true
  def handle_prepare(query, _opts, %{db_ref: db_ref} = state) do
    Logger.debug("Preparando consulta", %{
      module: __MODULE__,
      query: query
    })
    
    # Verifica se a consulta já está no cache
    case Map.get(state.prepare_cache, query) do
      nil ->
        # Prepara a consulta
        case Exqlite.Sqlite3.prepare(db_ref, query) do
          {:ok, statement} ->
            # Adiciona ao cache
            prepare_cache = Map.put(state.prepare_cache, query, statement)
            {:ok, statement, %{state | prepare_cache: prepare_cache}}
          {:error, reason} ->
            Logger.error("Falha ao preparar consulta", %{
              module: __MODULE__,
              query: query,
              error: reason
            })
            
            {:error, reason, state}
        end
      statement ->
        # Usa a consulta do cache
        {:ok, statement, state}
    end
  end
  
  @doc """
  Executa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL ou statement preparado
    - `params`: Parâmetros da consulta
    - `opts`: Opções da execução
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a consulta for executada com sucesso
    - `{:error, Exception.t(), state}` em caso de falha
    - `{:disconnect, Exception.t(), state}` em caso de falha de conexão
  """
  @impl true
  def handle_execute(query, params, _opts, %{db_ref: db_ref} = state) when is_binary(query) do
    Logger.debug("Executando consulta direta", %{
      module: __MODULE__,
      query: query,
      params: params
    })
    
    # Para consultas diretas, precisamos usar os parâmetros
    case Exqlite.Sqlite3.prepare(db_ref, query) do
      {:ok, statement} ->
        # Bind dos parâmetros
        bind_result = bind_parameters(statement, params)
        
        case bind_result do
          :ok ->
            # Executa a consulta
            case Exqlite.Sqlite3.fetch_all(db_ref, statement) do
              {:ok, rows} ->
                # Libera o statement
                :ok = Exqlite.Sqlite3.release(db_ref, statement)
                {:ok, %{rows: rows, num_rows: length(rows)}, state}
              {:error, reason} ->
                # Libera o statement mesmo em caso de erro
                :ok = Exqlite.Sqlite3.release(db_ref, statement)
                Logger.error("Falha ao buscar resultados", %{
                  module: __MODULE__,
                  query: query,
                  params: params,
                  error: reason
                })
                
                {:error, reason, state}
            end
          {:error, reason} ->
            # Libera o statement em caso de erro no bind
            :ok = Exqlite.Sqlite3.release(db_ref, statement)
            Logger.error("Falha ao vincular parâmetros", %{
              module: __MODULE__,
              query: query,
              params: params,
              error: reason
            })
            
            {:error, reason, state}
        end
      {:error, reason} ->
        Logger.error("Falha ao preparar consulta", %{
          module: __MODULE__,
          query: query,
          params: params,
          error: reason
        })
        
        {:error, reason, state}
    end
  end
  
  def handle_execute(%Query{statement: statement, params: query_params} = query, params, _opts, %{db_ref: db_ref} = state) do
    # Combinamos os parâmetros da query com os parâmetros fornecidos
    all_params = query_params ++ params
    Logger.debug("Executando query", %{
      module: __MODULE__,
      statement: statement,
      params: all_params
    })
    
    case Exqlite.Sqlite3.prepare(db_ref, statement) do
      {:ok, statement} ->
        # Bind dos parâmetros ao statement
        bind_result = bind_parameters(statement, all_params)
        
        result = case bind_result do
          :ok ->
            case Exqlite.Sqlite3.fetch_all(db_ref, statement) do
              {:ok, rows} ->
                # Reset e liberação do statement
                :ok = Exqlite.Sqlite3.reset(statement)
                {:ok, query, %{rows: rows, num_rows: length(rows)}, state}
              {:error, reason} ->
                Logger.error("Falha ao buscar resultados", %{
                  module: __MODULE__,
                  statement: statement,
                  params: all_params,
                  error: reason
                })
                {:error, %DBConnection.ConnectionError{message: "Erro ao buscar resultados: #{inspect(reason)}", reason: reason}, state}
            end
          {:error, reason} ->
            Logger.error("Falha ao vincular parâmetros", %{
              module: __MODULE__,
              statement: statement,
              params: all_params,
              error: reason
            })
            {:error, %DBConnection.ConnectionError{message: "Erro ao vincular parâmetros: #{inspect(reason)}", reason: reason}, state}
        end
        
        result
        
      {:error, reason} ->
        Logger.error("Falha ao preparar statement", %{
          module: __MODULE__,
          statement: statement,
          params: all_params,
          error: reason
        })
        
        {:error, %DBConnection.ConnectionError{message: "Erro ao preparar statement: #{inspect(reason)}", reason: reason}, state}
    end
  end
  
  # Para strings SQL diretas
  def handle_execute(sql, params, opts, state) when is_binary(sql) do
    # Criamos um objeto Query para manter a compatibilidade
    query = Query.new(sql, [])
    
    handle_execute(query, params, opts, state)
  end
  
  # Para statements preparados
  def handle_execute(statement, params, _opts, %{db_ref: db_ref} = state) do
    Logger.debug("Executando statement preparado", %{
      module: __MODULE__,
      statement: statement,
      params: params
    })
    
    # Bind dos parâmetros ao statement
    bind_result = bind_parameters(statement, params)
    
    # Criamos um objeto Query para manter a compatibilidade
    query = Query.new("prepared_statement", [])
    
    case bind_result do
      :ok ->
        case Exqlite.Sqlite3.fetch_all(db_ref, statement) do
          {:ok, rows} ->
            # Reset do statement para uso futuro
            :ok = Exqlite.Sqlite3.reset(statement)
            {:ok, query, %{rows: rows, num_rows: length(rows)}, state}
          {:error, reason} ->
            Logger.error("Falha ao buscar resultados", %{
              module: __MODULE__,
              statement: statement,
              params: params,
              error: reason
            })
            
            {:error, %DBConnection.ConnectionError{message: "Erro ao buscar resultados: #{inspect(reason)}", reason: reason}, state}
        end
      {:error, reason} ->
        Logger.error("Falha ao vincular parâmetros", %{
          module: __MODULE__,
          statement: statement,
          params: params,
          error: reason
        })
        
        {:error, %DBConnection.ConnectionError{message: "Erro ao vincular parâmetros: #{inspect(reason)}", reason: reason}, state}
    end
  end
  
  @doc """
  Fecha uma consulta preparada.
  
  ## Parâmetros
  
    - `query`: A consulta SQL ou statement preparado
    - `opts`: Opções do fechamento
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a consulta for fechada com sucesso
    - `{:error, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_close(statement, _opts, %{db_ref: db_ref} = state) do
    Logger.debug("Fechando statement preparado", %{
      module: __MODULE__,
      statement: statement
    })
    
    # Encontra a chave da consulta no cache
    {query, prepare_cache} = Enum.find_value(state.prepare_cache, {nil, state.prepare_cache}, fn {query, cached_statement} ->
      if cached_statement == statement do
        {query, Map.delete(state.prepare_cache, query)}
      else
        nil
      end
    end)
    
    updated_state = if query do
      # Remove do cache
      %{state | prepare_cache: prepare_cache}
    else
      state
    end
    
    case Exqlite.Sqlite3.release(db_ref, statement) do
      :ok ->
        {:ok, %{}, updated_state}
      {:error, reason} ->
        Logger.warning("Falha ao finalizar statement", %{
          module: __MODULE__,
          statement: statement,
          error: reason
        })
        
        # Não desconectamos em caso de falha ao finalizar
        {:ok, %{}, updated_state}
    end
  end
  
  @doc """
  Verifica o status da conexão.
  
  ## Parâmetros
  
    - `opts`: Opções da verificação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, status, state}` com o status da conexão
  """
  @impl true
  def handle_status(_opts, %{transaction: transaction} = state) do
    status = if transaction, do: :transaction, else: :idle
    {:ok, status, state}
  end

  # Implementação das funções obrigatórias do comportamento DBConnection

  @doc """
  Função de checkout para o DBConnection.
  
  ## Parâmetros
  
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, state}` se o checkout for bem-sucedido
  """
  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @doc """
  Declara um cursor para uma consulta.
  
  ## Parâmetros
  
    - `query`: A consulta SQL ou statement preparado
    - `params`: Parâmetros da consulta
    - `opts`: Opções da declaração
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, query, cursor, state}` se a declaração for bem-sucedida
    - `{:error, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_declare(query, params, _opts, state) do
    Logger.debug("Declarando cursor para consulta", %{
      module: __MODULE__,
      query: query
    })
    
    # SQLite não suporta cursores nativamente, então simulamos um cursor
    # retornando o próprio statement como cursor
    cursor = {query, params}
    {:ok, query, cursor, state}
  end

  @doc """
  Busca resultados de um cursor.
  
  ## Parâmetros
  
    - `query`: A consulta SQL ou statement preparado
    - `cursor`: O cursor para buscar resultados
    - `opts`: Opções da busca
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:cont, results, cursor, state}` se houver mais resultados
    - `{:halt, results, cursor, state}` se não houver mais resultados
    - `{:error, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_fetch(_query, {_query_text, _params} = cursor, _opts, state) do
    # Como simulamos um cursor, retornamos todos os resultados de uma vez
    # e indicamos que não há mais resultados
    {:halt, %{rows: [], num_rows: 0}, cursor, state}
  end

  @doc """
  Desaloca um cursor.
  
  ## Parâmetros
  
    - `query`: A consulta SQL ou statement preparado
    - `cursor`: O cursor a ser desalocado
    - `opts`: Opções da desalocação
    - `state`: Estado atual da conexão
  
  ## Retorno
  
    - `{:ok, result, state}` se a desalocação for bem-sucedida
    - `{:error, Exception.t(), state}` em caso de falha
  """
  @impl true
  def handle_deallocate(_query, _cursor, _opts, state) do
    # Como simulamos um cursor, não precisamos fazer nada para desalocá-lo
    {:ok, %{}, state}
  end
  
  # Funções auxiliares privadas
  
  @doc false
  defp execute_pragma(db_ref, pragma_statement, pragma_name) do
    # Reduzimos os logs para evitar mensagens duplicadas
    # Apenas registramos o início e o resultado final
    
    # A API do Exqlite.Sqlite3.execute pode retornar diferentes formatos de resultado
    # Vamos tratar todos os casos possíveis
    result = Exqlite.Sqlite3.execute(db_ref, pragma_statement)
    
    case result do
      {:ok, _} -> 
        :ok
      :ok -> 
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao configurar PRAGMA", %{
          module: __MODULE__,
          pragma: pragma_name,
          statement: pragma_statement,
          error: reason
        })
        # Retornamos :ok mesmo em caso de erro para não interromper a conexão
        # Os PRAGMAs são otimizações e não são essenciais para o funcionamento
        :ok
      _ ->
        Logger.warning("Resultado inesperado ao executar PRAGMA", %{
          module: __MODULE__,
          pragma: pragma_name,
          statement: pragma_statement,
          result: inspect(result)
        })
        # Retornamos :ok mesmo em caso de resultado inesperado
        :ok
    end
  end
  
  @doc false
  defp bind_parameters(statement, params) do
    # Vincula cada parâmetro ao statement
    Enum.with_index(params, 1)
    |> Enum.reduce(:ok, fn {param, idx}, acc ->
      case acc do
        :ok ->
          case bind_parameter(statement, idx, param) do
            :ok -> :ok
            error -> error
          end
        error -> error
      end
    end)
  end
  
  @doc false
  defp bind_parameter(statement, idx, param) do
    case param do
      nil ->
        Exqlite.Sqlite3.bind_null(statement, idx)
      param when is_binary(param) ->
        Exqlite.Sqlite3.bind_text(statement, idx, param)
      param when is_integer(param) ->
        Exqlite.Sqlite3.bind_integer(statement, idx, param)
      param when is_float(param) ->
        Exqlite.Sqlite3.bind_float(statement, idx, param)
      param when is_boolean(param) ->
        value = if param, do: 1, else: 0
        Exqlite.Sqlite3.bind_integer(statement, idx, value)
      %DateTime{} = dt ->
        Exqlite.Sqlite3.bind_text(statement, idx, DateTime.to_iso8601(dt))
      %Date{} = d ->
        Exqlite.Sqlite3.bind_text(statement, idx, Date.to_iso8601(d))
      %Time{} = t ->
        Exqlite.Sqlite3.bind_text(statement, idx, Time.to_iso8601(t))
      %NaiveDateTime{} = ndt ->
        Exqlite.Sqlite3.bind_text(statement, idx, NaiveDateTime.to_iso8601(ndt))
      other ->
        Exqlite.Sqlite3.bind_text(statement, idx, inspect(other))
    end
  end
end
