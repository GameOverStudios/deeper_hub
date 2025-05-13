defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Módulo genérico para operações CRUD dinâmicas em tabelas Mnesia.
  Permite a manipulação de diferentes tabelas sem a necessidade de duplicar funções.
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
    # Reutiliza a função insert, pois :mnesia.write/1 atualiza se a chave já existir.
    insert(table_name, record)
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

    case :mnesia.transaction(fn ->
           :mnesia.delete({table_name, key})
         end) do
      {:atomic, :ok} ->
        Logger.info("Registro deletado com sucesso da tabela #{table_name}", %{key: key})
        {:ok, :deleted}

      {:aborted, reason} ->
        Logger.error("Falha ao deletar registro da tabela #{table_name}", %{
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
  # Adicionado `is_list(match_spec)` se for sempre lista
  def match(table_name, match_spec) when is_atom(table_name) do
    Logger.info("Tentando buscar registros na tabela #{table_name} com match_spec", %{
      match_spec: match_spec
    })

    # Obter a aridade da tabela para verificar se a match_spec está correta
    case :mnesia.table_info(table_name, :arity) do
      arity when is_integer(arity) and arity > 0 ->
        # Criar uma match_head com apenas wildcards (:_)
        match_head = List.duplicate(:_, arity) |> List.to_tuple()
        # Construir a match_spec sem especificar o nome da tabela no match_head
        corrected_match_spec = [{match_head, [], [:'$_']}]
        
        Logger.info("Match spec corrigida para tabela #{table_name}: #{inspect(corrected_match_spec)}")
        
        case :mnesia.transaction(fn ->
               :mnesia.select(table_name, corrected_match_spec)
             end) do
          {:atomic, records_list} ->
            Logger.info(
              "#{length(records_list)} registros encontrados na tabela #{table_name}",
              %{count: length(records_list)}
            )

            {:ok, records_list}

          {:aborted, reason} ->
            Logger.error("Falha ao buscar registros na tabela #{table_name}", %{
              reason: reason
            })

            {:error, reason}
        end
        
      {:error, reason} ->
        Logger.error("Falha ao obter aridade da tabela #{table_name}", %{
          reason: reason
        })
        
        {:error, {:table_error, reason}}
    end
  end

  # Dentro de c:\New\lib\Deeper_Hub\Core\Data\repository.ex

    @spec all(atom()) :: {:ok, list(tuple())} | {:error, any()}
    def all(table) when is_atom(table) do
      Logger.debug("[TRACE] Iniciando Repository.all/1 para tabela: #{inspect(table)}")

      transaction_result =
        :mnesia.transaction(fn ->
          Logger.debug("[TRACE] Dentro da transação para Repository.all/1")

          case :mnesia.table_info(table, :record_name) do
            record_name when is_atom(record_name) ->
              Logger.debug("[TRACE] table_info(:record_name) OK: #{inspect(record_name)}")
              case :mnesia.table_info(table, :arity) do
                arity when is_integer(arity) and arity > 0 ->
                  Logger.debug("[TRACE] table_info(:arity) OK: #{inspect(arity)}")
                  # Criar uma match_head com apenas wildcards (:_)
                  match_head = List.duplicate(:_, arity) |> List.to_tuple()
                  # Construir a match_spec sem especificar o nome da tabela no match_head
                  match_spec = [{match_head, [], [:'$_']}]
                  # Também vamos logar a aridade para debug
                  Logger.debug("[TRACE] Aridade da tabela: #{arity}, Match head: #{inspect(match_head)}")
                  Logger.debug("[TRACE] Match spec construída: #{inspect(match_spec)}")

                  # Envolver :mnesia.select em try...catch
                  select_outcome =
                    try do
                      records = :mnesia.select(table, match_spec)
                      Logger.debug("[TRACE] :mnesia.select/2 retornou (sucesso presumido): #{inspect(records)}")
                      {:ok_select, records} # Sucesso
                    catch
                      kind, reason_details ->
                        stacktrace = __STACKTRACE__
                        Logger.error("[TRACE] :mnesia.select/2 CAUSOU EXCEÇÃO:")
                        Logger.error("[TRACE]   Kind: #{inspect(kind)}")
                        Logger.error("[TRACE]   Reason: #{inspect(reason_details)}")
                        Logger.error("[TRACE]   Stacktrace: #{inspect(stacktrace)}")
                        {:exception_in_select, kind, reason_details, stacktrace} # Falha com stacktrace
                    end

                  # Decidir o que a função da transação retorna
                  case select_outcome do
                    {:ok_select, records_from_select} ->
                      records_from_select # Retorna os registros para :mnesia.transaction
                    {:exception_in_select, kind, reason_details, stacktrace} ->
                      # Abortar a transação com detalhes da exceção do select
                      :mnesia.abort({:select_failed, kind, reason_details, stacktrace})
                  end

                {:error, {:no_exists, ^table, :arity}} ->
                  Logger.error("[TRACE] Erro ao buscar :arity: Tabela '#{table}' não possui aridade.")
                  :mnesia.abort({:no_exists, table, :arity})
                other_arity_error ->
                  Logger.error("[TRACE] Erro inesperado ao obter :arity: #{inspect(other_arity_error)}")
                  :mnesia.abort({:unexpected_arity_error, other_arity_error})
              end
            {:error, {:no_exists, ^table, :record_name}} ->
              Logger.error("[TRACE] Erro ao buscar :record_name: Tabela '#{table}' não possui nome de registro.")
              :mnesia.abort({:no_exists, table, :record_name})
            other_record_name_error ->
              Logger.error("[TRACE] Erro inesperado ao obter :record_name: #{inspect(other_record_name_error)}")
              :mnesia.abort({:unexpected_record_name_error, other_record_name_error})
          end
        end)

      Logger.debug("[TRACE] Resultado final da transação: #{inspect(transaction_result)}")

      case transaction_result do
        {:atomic, records} ->
          Logger.debug("[TRACE] Transação bem-sucedida. Registros: #{inspect(records)}")
          {:ok, records}
        {:aborted, {:no_exists, ^table, type}} when type in [:record_name, :arity] ->
          Logger.error("[TRACE] Falha: Tabela '#{table}' não encontrada (#{type}).")
          {:error, {:table_does_not_exist, table}}
        {:aborted, {:select_failed, kind, reason_details, stacktrace}} -> # Captura o aborto customizado com stacktrace
          Logger.error("""
          [TRACE] Transação abortada porque :mnesia.select/2 falhou:
            Kind: #{inspect(kind)}
            Reason: #{inspect(reason_details)}
            Stacktrace: #{inspect(stacktrace)}
          """)
          {:error, {:mnesia_error, {:select_failed_due_to_exception, {kind, reason_details}}}}
        {:aborted, reason} -> # Outros abortos, incluindo o :badarg original se não for exceção
          Logger.error("[TRACE] Erro na transação Mnesia (aborted): #{inspect(reason)}")
          {:error, {:mnesia_error, reason}}
        other_error ->
          Logger.error("[TRACE] Erro inesperado fora da transação: #{inspect(other_error)}")
          {:error, {:unexpected_error, other_error}}
      end
    end
end
