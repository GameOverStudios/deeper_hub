defmodule Deeper_Hub.Core.Data.DBConnection.SchemaAdapter do
  @moduledoc """
  Adaptador para usar schemas Ecto com o DBConnection.

  Este módulo fornece funções para converter schemas Ecto em consultas SQL
  e resultados SQL em schemas Ecto, facilitando a transição do Repo para o DBConnection.
  """

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Pool

  @doc """
  Insere um novo registro no banco de dados.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `attrs`: Atributos para o novo registro
    - `opts`: Opções adicionais

  ## Retorno

    - `{:ok, struct}` se o registro for inserido com sucesso
    - `{:error, changeset}` em caso de falha na validação
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec insert(module(), map(), Keyword.t()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def insert(schema, attrs, opts \\ []) do
    Logger.debug("Inserindo registro", %{
      module: __MODULE__,
      schema: schema,
      attrs: attrs
    })

    # Cria um changeset com os atributos
    changeset = schema.changeset(struct(schema), attrs)

    # Verifica se o changeset é válido
    if changeset.valid? do
      # Extrai os campos e valores do changeset
      changes = changeset.changes

      # Obtém o nome da tabela do schema
      table_name = schema.__schema__(:source)

      # Gera os nomes dos campos e placeholders para a consulta
      fields = Map.keys(changes)
      field_names = Enum.map_join(fields, ", ", &to_string/1)
      placeholders = Enum.map_join(1..length(fields), ", ", fn _ -> "?" end)

      # Gera a consulta SQL
      query = "INSERT INTO #{table_name} (#{field_names}) VALUES (#{placeholders}) RETURNING *"

      # Obtém os valores dos campos na ordem correta
      values = Enum.map(fields, &Map.get(changes, &1))

      # Executa a consulta
      case Pool.query(query, values, opts) do
        {:ok, %{rows: [row | _]}} ->
          # Converte o resultado em uma struct do schema
          struct = row_to_struct(schema, row, fields)
          {:ok, struct}
        {:error, reason} ->
          Logger.error("Falha ao inserir registro", %{
            module: __MODULE__,
            schema: schema,
            error: reason
          })

          {:error, reason}
      end
    else
      # Retorna o changeset inválido
      {:error, changeset}
    end
  end

  @doc """
  Busca um registro pelo ID.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado
    - `opts`: Opções adicionais

  ## Retorno

    - `{:ok, struct}` se o registro for encontrado
    - `{:error, :not_found}` se o registro não for encontrado
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec get(module(), term(), Keyword.t()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def get(schema, id, opts \\ []) do
    Logger.debug("Buscando registro por ID", %{
      module: __MODULE__,
      schema: schema,
      id: id
    })

    # Obtém o nome da tabela do schema
    table_name = schema.__schema__(:source)

    # Obtém o nome do campo de ID do schema
    id_field = schema.__schema__(:primary_key) |> List.first()

    # Gera a consulta SQL
    query = "SELECT * FROM #{table_name} WHERE #{id_field} = ? LIMIT 1"

    # Executa a consulta
    case Pool.query(query, [id], opts) do
      {:ok, %{rows: [row | _]}} ->
        # Obtém os nomes dos campos do schema
        fields = schema.__schema__(:fields)

        # Converte o resultado em uma struct do schema
        struct = row_to_struct(schema, row, fields)
        {:ok, struct}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        Logger.error("Falha ao buscar registro por ID", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          error: reason
        })

        {:error, reason}
    end
  end

  @doc """
  Atualiza um registro existente.

  ## Parâmetros

    - `struct`: A struct Ecto a ser atualizada
    - `attrs`: Novos atributos para o registro
    - `opts`: Opções adicionais

  ## Retorno

    - `{:ok, struct}` se o registro for atualizado com sucesso
    - `{:error, changeset}` em caso de falha na validação
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec update(Ecto.Schema.t(), map(), Keyword.t()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def update(struct, attrs, opts \\ []) do
    Logger.debug("Atualizando registro", %{
      module: __MODULE__,
      struct: struct,
      attrs: attrs
    })

    schema = struct.__struct__

    # Cria um changeset com os atributos
    changeset = schema.changeset(struct, attrs)

    # Verifica se o changeset é válido
    if changeset.valid? do
      # Extrai os campos e valores do changeset
      changes = changeset.changes

      # Se não houver mudanças, retorna o struct original
      if Enum.empty?(changes) do
        {:ok, struct}
      else
        # Obtém o nome da tabela do schema
        table_name = schema.__schema__(:source)

        # Obtém o nome do campo de ID do schema
        id_field = schema.__schema__(:primary_key) |> List.first()
        id_value = Map.get(struct, id_field)

        # Gera os pares campo=valor para a consulta
        fields = Map.keys(changes)
        set_clause = Enum.map_join(fields, ", ", fn field -> "#{field} = ?" end)

        # Gera a consulta SQL
        query = "UPDATE #{table_name} SET #{set_clause} WHERE #{id_field} = ? RETURNING *"

        # Obtém os valores dos campos na ordem correta
        values = Enum.map(fields, &Map.get(changes, &1)) ++ [id_value]

        # Executa a consulta
        case Pool.query(query, values, opts) do
          {:ok, %{rows: [row | _]}} ->
            # Converte o resultado em uma struct do schema
            updated_struct = row_to_struct(schema, row, schema.__schema__(:fields))
            {:ok, updated_struct}
          {:error, reason} ->
            Logger.error("Falha ao atualizar registro", %{
              module: __MODULE__,
              struct: struct,
              error: reason
            })

            {:error, reason}
        end
      end
    else
      # Retorna o changeset inválido
      {:error, changeset}
    end
  end

  @doc """
  Deleta um registro.

  ## Parâmetros

    - `struct`: A struct Ecto a ser deletada
    - `opts`: Opções adicionais

  ## Retorno

    - `{:ok, struct}` se o registro for deletado com sucesso
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec delete(Ecto.Schema.t(), Keyword.t()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def delete(struct, opts \\ []) do
    Logger.debug("Deletando registro", %{
      module: __MODULE__,
      struct: struct
    })

    schema = struct.__struct__

    # Obtém o nome da tabela do schema
    table_name = schema.__schema__(:source)

    # Obtém o nome do campo de ID do schema
    id_field = schema.__schema__(:primary_key) |> List.first()
    id_value = Map.get(struct, id_field)

    # Gera a consulta SQL
    query = "DELETE FROM #{table_name} WHERE #{id_field} = ?"

    # Executa a consulta
    case Pool.query(query, [id_value], opts) do
      {:ok, _} ->
        {:ok, struct}
      {:error, reason} ->
        Logger.error("Falha ao deletar registro", %{
          module: __MODULE__,
          struct: struct,
          error: reason
        })

        {:error, reason}
    end
  end

  @doc """
  Lista todos os registros de um schema, com opções de filtro e paginação.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `filters`: Condições de filtro (ex: `[name: "John", age: 30]`)
    - `opts`: Opções de paginação (`:limit`, `:offset`)

  ## Retorno

    - `{:ok, list_of_structs}` contendo a lista de registros
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec list(module(), Keyword.t(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def list(schema, filters \\ [], opts \\ []) do
    Logger.debug("Listando registros", %{
      module: __MODULE__,
      schema: schema,
      filters: filters,
      opts: opts
    })

    # Obtém o nome da tabela do schema
    table_name = schema.__schema__(:source)

    # Gera a cláusula WHERE se houver filtros
    {where_clause, filter_values} =
      if Enum.empty?(filters) do
        {"", []}
      else
        filter_fields = Keyword.keys(filters)
        where_conditions = Enum.map_join(filter_fields, " AND ", fn field -> "#{field} = ?" end)
        filter_values = Enum.map(filter_fields, &Keyword.get(filters, &1))

        {" WHERE " <> where_conditions, filter_values}
      end

    # Gera a cláusula LIMIT e OFFSET se fornecidos
    limit_clause =
      if Keyword.has_key?(opts, :limit) do
        " LIMIT #{Keyword.get(opts, :limit)}"
      else
        ""
      end

    offset_clause =
      if Keyword.has_key?(opts, :offset) do
        " OFFSET #{Keyword.get(opts, :offset)}"
      else
        ""
      end

    # Gera a consulta SQL
    query = "SELECT * FROM #{table_name}#{where_clause}#{limit_clause}#{offset_clause}"

    # Executa a consulta
    case Pool.query(query, filter_values, opts) do
      {:ok, %{rows: rows}} ->
        # Obtém os nomes dos campos do schema
        fields = schema.__schema__(:fields)

        # Converte os resultados em structs do schema
        structs = Enum.map(rows, &row_to_struct(schema, &1, fields))
        {:ok, structs}
      {:error, reason} ->
        Logger.error("Falha ao listar registros", %{
          module: __MODULE__,
          schema: schema,
          error: reason
        })

        {:error, reason}
    end
  end

  @doc """
  Conta o número de registros de um schema, com opções de filtro.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `filters`: Condições de filtro (ex: `[name: "John", age: 30]`)
    - `opts`: Opções adicionais

  ## Retorno

    - `{:ok, count}` contendo o número de registros
    - `{:error, reason}` em caso de falha no banco de dados
  """
  @spec count(module(), Keyword.t(), Keyword.t()) :: {:ok, integer()} | {:error, term()}
  def count(schema, filters \\ [], opts \\ []) do
    Logger.debug("Contando registros", %{
      module: __MODULE__,
      schema: schema,
      filters: filters
    })

    # Obtém o nome da tabela do schema
    table_name = schema.__schema__(:source)

    # Gera a cláusula WHERE se houver filtros
    {where_clause, filter_values} =
      if Enum.empty?(filters) do
        {"", []}
      else
        filter_fields = Keyword.keys(filters)
        where_conditions = Enum.map_join(filter_fields, " AND ", fn field -> "#{field} = ?" end)
        filter_values = Enum.map(filter_fields, &Keyword.get(filters, &1))

        {" WHERE " <> where_conditions, filter_values}
      end

    # Gera a consulta SQL
    query = "SELECT COUNT(*) FROM #{table_name}#{where_clause}"

    # Executa a consulta
    case Pool.query(query, filter_values, opts) do
      {:ok, %{rows: [[count]]}} ->
        {:ok, count}
      {:error, reason} ->
        Logger.error("Falha ao contar registros", %{
          module: __MODULE__,
          schema: schema,
          error: reason
        })

        {:error, reason}
    end
  end

  # Funções privadas

  # Converte uma linha de resultado em uma struct do schema
  defp row_to_struct(schema, row, fields) do
    # Cria um mapa com os campos e valores
    field_values = Enum.zip(fields, row) |> Enum.into(%{})

    # Cria uma struct do schema com os valores
    struct(schema, field_values)
  end
end
