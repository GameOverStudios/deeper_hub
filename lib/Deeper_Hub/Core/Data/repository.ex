defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Módulo genérico para operações CRUD dinâmicas em tabelas Mnesia.
  Permite a manipulação de diferentes tabelas sem a necessidade de duplicar funções.
  
  Fornece funções para inserção, busca, atualização, exclusão e consulta de registros em tabelas Mnesia.
  Todas as funções são projetadas para serem genéricas e funcionarem com qualquer tabela Mnesia.
  """

  alias Deeper_Hub.Core.Logger

  @type table_name :: atom()
  @type record_key :: any()
  @type record :: tuple()
  @type mnesia_match_spec :: list()
  @type error_reason :: atom() | {:aborted, any()} | any()

  @doc """
  Insere um novo registro em uma tabela Mnesia.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.
    - `record`: A tupla do registro a ser inserida. O primeiro elemento da tupla
                deve ser o nome da tabela (o mesmo que `table_name`).

  ## Retorno

    - `{:ok, record}` em caso de sucesso.
    - `{:error, reason}` em caso de falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 1, "Alice", "alice@example.com"})
      {:ok, {:users, 1, "Alice", "alice@example.com"}}

      iex> Deeper_Hub.Core.Data.Repository.insert(:products, {:products, "p123", "Laptop", 1200.00})
      {:ok, {:products, "p123", "Laptop", 1200.00}}
  """
  @spec insert(table_name(), record()) :: {:ok, record()} | {:error, error_reason()}
  def insert(table_name, record) when is_atom(table_name) and is_tuple(record) do
    Logger.info("Tentando inserir registro na tabela #{table_name}", %{record: record})

    # Extrair a chave do registro (assumindo que é o segundo elemento da tupla)
    key = elem(record, 1)

    # Verificar se já existe um registro com essa chave
    case find(table_name, key) do
      {:ok, _existing_record} ->
        # Registro já existe, retornar erro
        Logger.warning("Falha ao inserir registro na tabela #{table_name}: chave duplicada", %{
          key: key,
          record: record
        })
        {:error, :duplicate_key}

      {:error, :not_found} ->
        # Registro não existe, podemos inserir
        case :mnesia.transaction(fn ->
               :mnesia.write(record)
             end) do
          {:atomic, :ok} ->
            Logger.info("Registro inserido com sucesso na tabela #{table_name}", %{record: record})
            {:ok, record}

          {:aborted, reason} ->
            Logger.error("Falha ao inserir registro na tabela #{table_name}", %{
              reason: reason,
              record: record
            })

            {:error, reason}
        end

      {:error, reason} ->
        # Outro erro ao buscar o registro
        Logger.error("Falha ao verificar existência do registro na tabela #{table_name}", %{
          reason: reason,
          key: key
        })

        {:error, reason}
    end
  end

  @doc """
  Busca um registro em uma tabela Mnesia pela sua chave primária.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.
    - `key`: A chave primária do registro a ser buscado.

  ## Retorno

    - `{:ok, record}` se o registro for encontrado.
    - `{:error, :not_found}` se o registro não for encontrado.
    - `{:error, reason}` em caso de outra falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 1, "Bob", "bob@example.com"})
      iex> Deeper_Hub.Core.Data.Repository.find(:users, 1)
      {:ok, {:users, 1, "Bob", "bob@example.com"}}

      iex> Deeper_Hub.Core.Data.Repository.find(:users, 999)
      {:error, :not_found}
  """
  @spec find(table_name(), record_key()) ::
          {:ok, record()} | {:error, :not_found | error_reason()}
  def find(table_name, key) when is_atom(table_name) do
    Logger.info("Tentando buscar registro na tabela #{table_name} com chave #{inspect(key)}")

    case :mnesia.transaction(fn ->
           :mnesia.read(table_name, key)
         end) do
      {:atomic, [record]} ->
        Logger.info("Registro encontrado na tabela #{table_name}", %{key: key, record: record})
        {:ok, record}

      {:atomic, []} ->
        Logger.warning(
          "Registro não encontrado na tabela #{table_name} com chave #{inspect(key)}"
        )

        {:error, :not_found}

      {:aborted, reason} ->
        Logger.error("Falha ao buscar registro na tabela #{table_name}", %{
          reason: reason,
          key: key
        })

        {:error, reason}
    end
  end

  @doc """
  Atualiza um registro existente em uma tabela Mnesia.
  O registro é identificado pela chave primária contida no próprio registro.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela (deve corresponder ao primeiro elemento da tupla do registro).
    - `record`: A tupla do registro atualizado.

  ## Retorno

    - `{:ok, record}` em caso de sucesso.
    - `{:error, reason}` em caso de falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 2, "Charlie", "charlie@example.com"})
      iex> Deeper_Hub.Core.Data.Repository.update(:users, {:users, 2, "Charlie Brown", "charlie.brown@example.com"})
      {:ok, {:users, 2, "Charlie Brown", "charlie.brown@example.com"}}
  """
  @spec update(table_name(), record()) :: {:ok, record()} | {:error, error_reason()}
  def update(table_name, record) when is_atom(table_name) and is_tuple(record) do
    Logger.info("Tentando atualizar registro na tabela #{table_name}", %{record: record})
    
    # Extrai a chave do registro (assumindo que é o segundo elemento da tupla)
    key = elem(record, 1)
    
    # Verifica se o registro existe
    case find(table_name, key) do
      {:ok, _existing_record} ->
        # Executa a transação para atualizar o registro
        transaction_result =
          :mnesia.transaction(fn ->
            # Deleta o registro existente
            :mnesia.delete({table_name, key})
            # Insere o novo registro
            :mnesia.write(record)
          end)
        
        case transaction_result do
          {:atomic, :ok} ->
            Logger.info("Registro atualizado com sucesso na tabela #{table_name}", %{
              record: record,
              key: key
            })
            {:ok, record}
          {:aborted, reason} ->
            Logger.error("Falha ao atualizar registro na tabela #{table_name}", %{
              reason: reason,
              record: record,
              key: key
            })
            {:error, reason}
        end
        
      {:error, :not_found} ->
        # Se o registro não existe, simplesmente insere
        insert(table_name, record)
        
      {:error, reason} ->
        # Se ocorreu outro erro ao buscar o registro, propaga o erro
        {:error, reason}
    end
  end

  @doc """
  Deleta um registro de uma tabela Mnesia pela sua chave primária.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.
    - `key`: A chave primária do registro a ser deletado.

  ## Retorno

    - `{:ok, :deleted}` em caso de sucesso.
    - `{:error, reason}` em caso de falha (incluindo :not_found se a chave não existir).

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 3, "David", "david@example.com"})
      iex> Deeper_Hub.Core.Data.Repository.delete(:users, 3)
      {:ok, :deleted}

      iex> Deeper_Hub.Core.Data.Repository.delete(:users, 998)
      {:error, {:badarg, [...]}} # Mnesia pode retornar :badarg para chaves inexistentes em delete
  """
  @spec delete(table_name(), record_key()) ::
          {:ok, :deleted} | {:error, :not_found | error_reason()}
  def delete(table_name, key) when is_atom(table_name) do
    Logger.info("Tentando deletar registro na tabela #{table_name} com chave #{inspect(key)}")

    # Primeiro verificar se o registro existe
    case find(table_name, key) do
      {:ok, _record} ->
        # Registro existe, podemos deletar
        case :mnesia.transaction(fn ->
               :mnesia.delete({table_name, key})
             end) do
          {:atomic, :ok} ->
            Logger.info("Registro deletado com sucesso da tabela #{table_name}", %{key: key})
            {:ok, :deleted}

          {:aborted, reason} ->
            Logger.error("Falha ao deletar registro na tabela #{table_name}", %{
              reason: reason,
              key: key
            })

            {:error, reason}
        end

      {:error, :not_found} ->
        # Registro não existe
        Logger.warning("Tentativa de deletar registro inexistente na tabela #{table_name}", %{key: key})
        {:error, :not_found}

      {:error, reason} ->
        # Outro erro ao buscar o registro
        Logger.error("Falha ao verificar existência do registro na tabela #{table_name}", %{
          reason: reason,
          key: key
        })

        {:error, reason}
    end
  end

  @doc """
  Busca todos os registros em uma tabela Mnesia que correspondem a um padrão (match_spec).

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.
    - `match_spec`: A especificação de correspondência do Mnesia.

  ## Retorno

    - `{:ok, records_list}` uma lista de registros que correspondem.
    - `{:error, reason}` em caso de falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 4, "Eve", "eve@example.com"})
      iex> Deeper_Hub.Core.Data.Repository.insert(:users, {:users, 5, "Eva", "eva@example.com"})
      iex> match_spec = [{:users, :_, "Eve", :_}, [], [:'$_']]
      iex> Deeper_Hub.Core.Data.Repository.match(:users, match_spec)
      {:ok, [{:users, 4, "Eve", "eve@example.com"}]}
  """
  @spec match(table_name(), mnesia_match_spec()) ::
          {:ok, list(record())} | {:error, error_reason()}
  def match(table_name, match_spec) when is_atom(table_name) do
    Logger.info("Tentando buscar registros na tabela #{table_name} com match_spec", %{
      match_spec: match_spec
    })

    # Construir o padrão de busca
    pattern = if match_spec == [] do
      # Se não foi fornecido um padrão específico, buscar todos os registros
      case :mnesia.table_info(table_name, :arity) do
        arity when is_integer(arity) and arity > 0 ->
          # Criar uma tupla com o nome da tabela como primeiro elemento e wildcards para os demais campos
          List.to_tuple([table_name | List.duplicate(:_, arity - 1)])
        {:error, reason} ->
          Logger.error("Falha ao obter aridade da tabela #{table_name}", %{reason: reason})
          {:error, reason}
      end
    else
      # Usar o primeiro elemento da match_spec fornecida
      hd(match_spec)
    end

    # Verificar se pattern é um erro
    case pattern do
      {:error, reason} ->
        {:error, reason}
      _ ->
        Logger.debug("Padrão de busca: #{inspect(pattern)}")

        case :mnesia.transaction(fn ->
               :mnesia.match_object(table_name, pattern, :read)
             end) do
          {:atomic, records} ->
            Logger.info("Registros encontrados na tabela #{table_name}", %{
              count: length(records)
            })

            {:ok, records}

          {:aborted, reason} ->
            Logger.error("Falha ao buscar registros na tabela #{table_name}", %{
              reason: reason,
              pattern: pattern
            })

            {:error, reason}
        end
    end
  end

  @doc """
  Recupera todos os registros de uma tabela Mnesia.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.

  ## Retorno

    - `{:ok, records}` onde records é uma lista de todos os registros da tabela.
    - `{:error, reason}` em caso de falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.all(:users)
      {:ok, [{:users, 1, "Alice", "alice@example.com"}, {:users, 2, "Bob", "bob@example.com"}]}

      iex> Deeper_Hub.Core.Data.Repository.all(:empty_table)
      {:ok, []}
  """
  @spec all(table_name()) :: {:ok, list(record())} | {:error, error_reason()}
  def all(table) when is_atom(table) do
    Logger.debug("Iniciando Repository.all/1 para tabela: #{inspect(table)}")

    case build_match_spec(table, []) do
      {:ok, match_spec} ->
        Logger.debug("Match spec construída: #{inspect(match_spec)}")

        transaction_result =
          :mnesia.transaction(fn ->
            try do
              :mnesia.select(table, match_spec)
            catch
              kind, reason_details ->
                stacktrace = __STACKTRACE__
                Logger.error("Exceção ao executar select na tabela #{table}:")
                Logger.error("  Kind: #{inspect(kind)}")
                Logger.error("  Reason: #{inspect(reason_details)}")
                Logger.error("  Stacktrace: #{inspect(stacktrace)}")
                :mnesia.abort({:select_failed, kind, reason_details, stacktrace})
            end
          end)

        Logger.debug("Resultado da transação: #{inspect(transaction_result)}")

        case transaction_result do
          {:atomic, records} ->
            Logger.info("Registros recuperados com sucesso da tabela #{table}", %{
              count: length(records)
            })
            {:ok, records}
          {:aborted, {:no_exists, ^table, _type}} ->
            Logger.error("Tabela '#{table}' não encontrada")
            {:error, {:table_does_not_exist, table}}
          {:aborted, {:select_failed, kind, reason_details, _stacktrace}} ->
            Logger.error("Falha ao executar select na tabela #{table}")
            {:error, {:mnesia_error, {:select_failed, {kind, reason_details}}}}
          # Tratamento específico para o erro badarg na tabela schema
          {:aborted, {:badarg, :schema, _match_spec}} ->
            Logger.error("Erro de argumento inválido ao acessar a tabela schema")
            {:error, {:table_access_error, :schema, :badarg}}
          {:aborted, reason} ->
            Logger.error("Erro na transação Mnesia: #{inspect(reason)}")
            {:error, {:mnesia_error, reason}}
          error ->
            Logger.error("Erro inesperado: #{inspect(error)}")
            {:error, {:unexpected_error, error}}
        end

      {:error, reason} ->
        Logger.error("Falha ao construir match_spec para tabela #{table}", %{
          reason: reason
        })

        {:error, reason}
    end
  end

  @spec build_match_spec(table_name(), any()) :: 
          {:ok, mnesia_match_spec()} | {:error, error_reason()}
  defp build_match_spec(table_name, _input_match_spec) do
    # Constrói uma match_spec baseada na aridade da tabela
    try do
      case :mnesia.table_info(table_name, :arity) do
        arity when is_integer(arity) and arity > 0 ->
          # Criar uma match_head com apenas wildcards (:_)
          match_head = List.duplicate(:_, arity)
          {:ok, [{List.to_tuple(match_head), [], [:'$_']}]}

        {:error, {:no_exists, ^table_name, :arity}} ->
          Logger.error("Tabela '#{table_name}' não possui aridade definida")
          {:error, {:table_does_not_exist, table_name}}

        other_error ->
          Logger.error("Erro ao obter aridade da tabela #{table_name}: #{inspect(other_error)}")
          {:error, {:table_error, other_error}}
      end
    catch
      :exit, {:aborted, {:no_exists, ^table_name, _}} ->
        Logger.error("Tabela '#{table_name}' não existe")
        {:error, {:table_does_not_exist, table_name}}
      kind, reason ->
        Logger.error("Erro inesperado ao obter informações da tabela #{table_name}: #{inspect({kind, reason})}")
        {:error, {:unexpected_error, {kind, reason}}}
    end
  end
end
