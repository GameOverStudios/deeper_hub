defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Módulo genérico para operações CRUD dinâmicas em tabelas Mnesia.
  Permite a manipulação de diferentes tabelas sem a necessidade de duplicar funções.
  """

  alias Deeper_Hub.Core.Logger

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
  def insert(table_name, record) when is_atom(table_name) and is_tuple(record) do
    Logger.info("Tentando inserir registro na tabela #{table_name}", %{record: record})
    case :mnesia.transaction(fn ->
           :mnesia.write(record)
         end) do
      {:atomic, :ok} ->
        Logger.info("Registro inserido com sucesso na tabela #{table_name}", %{record: record})
        {:ok, record}
      {:aborted, reason} ->
        Logger.error("Falha ao inserir registro na tabela #{table_name}", %{reason: reason, record: record})
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
  def find(table_name, key) when is_atom(table_name) do
    Logger.info("Tentando buscar registro na tabela #{table_name} com chave #{inspect(key)}")
    case :mnesia.transaction(fn ->
           :mnesia.read(table_name, key)
         end) do
      {:atomic, [record]} ->
        Logger.info("Registro encontrado na tabela #{table_name}", %{key: key, record: record})
        {:ok, record}
      {:atomic, []} ->
        Logger.warning("Registro não encontrado na tabela #{table_name} com chave #{inspect(key)}")
        {:error, :not_found}
      {:aborted, reason} ->
        Logger.error("Falha ao buscar registro na tabela #{table_name}", %{reason: reason, key: key})
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
  def delete(table_name, key) when is_atom(table_name) do
    Logger.info("Tentando deletar registro na tabela #{table_name} com chave #{inspect(key)}")
    case :mnesia.transaction(fn ->
           :mnesia.delete({table_name, key})
         end) do
      {:atomic, :ok} ->
        Logger.info("Registro deletado com sucesso da tabela #{table_name}", %{key: key})
        {:ok, :deleted}
      {:aborted, reason} ->
        Logger.error("Falha ao deletar registro da tabela #{table_name}", %{reason: reason, key: key})
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
  def match(table_name, match_spec) when is_atom(table_name) do
    Logger.info("Tentando buscar registros na tabela #{table_name} com match_spec", %{match_spec: match_spec})
    case :mnesia.transaction(fn ->
           :mnesia.select(table_name, match_spec)
         end) do
      {:atomic, records_list} ->
        Logger.info("#{length(records_list)} registros encontrados na tabela #{table_name} com match_spec", %{count: length(records_list)})
        {:ok, records_list}
      {:aborted, reason} ->
        Logger.error("Falha ao buscar registros na tabela #{table_name} com match_spec", %{reason: reason})
        {:error, reason}
    end
  end

  @doc """
  Retorna todos os registros de uma tabela.

  ## Parâmetros

    - `table_name`: O átomo que representa o nome da tabela.

  ## Retorno

    - `{:ok, records_list}` uma lista de todos os registros da tabela.
    - `{:error, reason}` em caso de falha.

  ## Exemplos

      iex> Deeper_Hub.Core.Data.Repository.all(:users)
      {:ok, [...]}
  """
  def all(table_name) when is_atom(table_name) do
    Logger.info("Buscando todos os registros da tabela #{table_name}")
    match_spec = [{ {table_name, :_}, [], [:'$_'] }]
    match(table_name, match_spec)
  end
end
