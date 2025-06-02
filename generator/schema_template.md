defmodule DeeperHub.Core.Data.Schemas.{{MODULE_NAME}} do
  @moduledoc """
  Este schema armazena as informações de um {{SINGULAR_NAME}}.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Busca todos os registros de {{SINGULAR_NAME}}s na tabela {{TABLE_NAME}}.

  ## Parâmetros opcionais
    - `opts`: Mapa de opções
      - `:page` - Número da página para paginação (padrão: 1)
      - `:page_size` - Tamanho da página (padrão: 20)
      - `:order_by` - Campo para ordenação (padrão: "id")
      - `:order_direction` - Direção da ordenação ("asc" ou "desc", padrão: "asc")

  ## Retorno
    - Lista de mapas representando os registros
    - Metadados de paginação
  """
  @spec all(map()) :: {:ok, %{items: [map()], metadata: map()}} | {:error, any()}
  def all(opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    page_size = Map.get(opts, :page_size, 20)
    order_by = Map.get(opts, :order_by, "id")
    order_direction = Map.get(opts, :order_direction, "asc")
    
    offset = (page - 1) * page_size
    
    Logger.info("Buscando registros de {{TABLE_NAME}} (página #{page}, #{page_size} por página)...", module: __MODULE__)

    # Primeiro, obter contagem total para paginação
    count_sql = """
    SELECT COUNT(*) as total FROM {{TABLE_NAME}}
    """
    
    # Consulta principal com paginação e ordenação
    sql = """
    SELECT * FROM {{TABLE_NAME}}
    ORDER BY #{order_by} #{order_direction}
    LIMIT ? OFFSET ?
    """

    with {:ok, %{rows: [[total]]}} <- Repo.execute(count_sql),
         {:ok, %{rows: rows, columns: columns}} <- Repo.execute(sql, [page_size, offset]) do
      
      items = Enum.map(rows, fn row ->
        Enum.zip(columns, row) |> Enum.into(%{})
      end)
      
      total_pages = ceil(total / page_size)
      
      metadata = %{
        page: page,
        page_size: page_size,
        total_items: total,
        total_pages: total_pages,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
      
      Logger.info("Registros de {{TABLE_NAME}} recuperados com sucesso.", module: __MODULE__)
      {:ok, %{items: items, metadata: metadata}}
    else
      {:error, reason} ->
        Logger.error("Falha ao buscar registros de {{TABLE_NAME}}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca um {{SINGULAR_NAME}} pelo ID.

  ## Parâmetros
    - `id`: ID do registro a ser buscado

  ## Retorno
    - Mapa representando o registro encontrado ou nil se não encontrado
  """
  @spec get(String.t()) :: {:ok, map() | nil} | {:error, any()}
  def get(id) do
    Logger.info("Buscando {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)

    sql = """
    SELECT * FROM {{TABLE_NAME}} WHERE id = ?
    """

    case Repo.execute(sql, [id]) do
      {:ok, %{rows: [row], columns: columns}} ->
        result = Enum.zip(columns, row) |> Enum.into(%{})
        Logger.info("Registro de {{SINGULAR_NAME}} recuperado com sucesso.", module: __MODULE__)
        {:ok, result}

      {:ok, %{rows: []}} ->
        Logger.info("Nenhum registro de {{SINGULAR_NAME}} encontrado com ID: #{id}", module: __MODULE__)
        {:ok, nil}

      {:error, reason} ->
        Logger.error("Falha ao buscar {{SINGULAR_NAME}} com ID: #{id}, erro: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Cria um novo registro de {{SINGULAR_NAME}}.

  ## Parâmetros
    - `attrs`: Mapa com os atributos do registro a ser criado

  ## Retorno
    - ID do registro criado
  """
  @spec create(map()) :: {:ok, integer()} | {:error, any()}
  def create(attrs) do
    Logger.info("Criando novo registro de {{SINGULAR_NAME}}", module: __MODULE__)

    # Preparar campos e valores
    fields = Map.keys(attrs) |> Enum.filter(&(&1 not in [:id]))
    placeholders = Enum.map(fields, fn _ -> "?" end) |> Enum.join(", ")
    values = Enum.map(fields, &Map.get(attrs, &1))
    
    fields_str = fields
      |> Enum.map(&to_string/1)
      |> Enum.join(", ")

    sql = """
    INSERT INTO {{TABLE_NAME}} (#{fields_str})
    VALUES (#{placeholders})
    """

    case Repo.execute(sql, values) do
      {:ok, %{last_insert_id: id}} ->
        Logger.info("Registro de {{SINGULAR_NAME}} criado com sucesso. ID: #{id}", module: __MODULE__)
        {:ok, id}

      {:error, reason} ->
        Logger.error("Falha ao criar registro de {{SINGULAR_NAME}}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Atualiza um registro de {{SINGULAR_NAME}} existente.

  ## Parâmetros
    - `id`: ID do registro a ser atualizado
    - `attrs`: Mapa com os atributos a serem atualizados

  ## Retorno
    - :ok se sucesso, {:error, reason} se falha
  """
  @spec update(integer(), map()) :: :ok | {:error, any()}
  def update(id, attrs) do
    Logger.info("Atualizando registro de {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)

    # Preparar campos e valores para atualização
    fields = Map.keys(attrs) |> Enum.filter(&(&1 not in [:id, :inserted_at, :updated_at]))
    
    if Enum.empty?(fields) do
      Logger.info("Nenhum campo para atualizar.", module: __MODULE__)
      return :ok
    end
    
    # Criar string de atualização: "campo1 = ?, campo2 = ?, ..."
    update_str = fields
      |> Enum.map(&"#{&1} = ?")
      |> Enum.join(", ")
    
    # Valores para os placeholders, na ordem correta
    values = Enum.map(fields, &Map.get(attrs, &1)) ++ [id]

    sql = """
    UPDATE {{TABLE_NAME}}
    SET #{update_str}
    WHERE id = ?
    """

    case Repo.execute(sql, values) do
      {:ok, %{affected_rows: 1}} ->
        Logger.info("Registro de {{SINGULAR_NAME}} atualizado com sucesso.", module: __MODULE__)
        :ok

      {:ok, %{affected_rows: 0}} ->
        Logger.info("Nenhum registro de {{SINGULAR_NAME}} encontrado com ID: #{id}", module: __MODULE__)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Falha ao atualizar registro de {{SINGULAR_NAME}}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove um registro de {{SINGULAR_NAME}}.

  ## Parâmetros
    - `id`: ID do registro a ser removido

  ## Retorno
    - :ok se sucesso, {:error, reason} se falha
  """
  @spec delete(integer()) :: :ok | {:error, any()}
  def delete(id) do
    Logger.info("Excluindo registro de {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)

    sql = """
    DELETE FROM {{TABLE_NAME}}
    WHERE id = ?
    """

    case Repo.execute(sql, [id]) do
      {:ok, %{affected_rows: 1}} ->
        Logger.info("Registro de {{SINGULAR_NAME}} excluído com sucesso.", module: __MODULE__)
        :ok

      {:ok, %{affected_rows: 0}} ->
        Logger.info("Nenhum registro de {{SINGULAR_NAME}} encontrado com ID: #{id}", module: __MODULE__)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Falha ao excluir registro de {{SINGULAR_NAME}}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca registros de {{SINGULAR_NAME}} por um campo específico.

  ## Parâmetros
    - `field`: Campo a ser usado na busca
    - `value`: Valor a ser buscado
    - `opts`: Mapa de opções
      - `:page` - Número da página para paginação (padrão: 1)
      - `:page_size` - Tamanho da página (padrão: 20)
      - `:order_by` - Campo para ordenação (padrão: "id")
      - `:order_direction` - Direção da ordenação ("asc" ou "desc", padrão: "asc")

  ## Retorno
    - Lista de mapas representando os registros encontrados
    - Metadados de paginação
  """
  @spec get_by(atom(), any(), map()) :: {:ok, %{items: [map()], metadata: map()}} | {:error, any()}
  def get_by(field, value, opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    page_size = Map.get(opts, :page_size, 20)
    order_by = Map.get(opts, :order_by, "id")
    order_direction = Map.get(opts, :order_direction, "asc")
    
    offset = (page - 1) * page_size
    
    Logger.info("Buscando {{SINGULAR_NAME}}s por #{field}: #{value} (página #{page}, #{page_size} por página)...", module: __MODULE__)

    # Primeiro, obter contagem total para paginação
    count_sql = """
    SELECT COUNT(*) as total FROM {{TABLE_NAME}} WHERE #{field} = ?
    """
    
    # Consulta principal com paginação e ordenação
    sql = """
    SELECT * FROM {{TABLE_NAME}} 
    WHERE #{field} = ?
    ORDER BY #{order_by} #{order_direction}
    LIMIT ? OFFSET ?
    """

    with {:ok, %{rows: [[total]]}} <- Repo.execute(count_sql, [value]),
         {:ok, %{rows: rows, columns: columns}} <- Repo.execute(sql, [value, page_size, offset]) do
      
      items = Enum.map(rows, fn row ->
        Enum.zip(columns, row) |> Enum.into(%{})
      end)
      
      total_pages = ceil(total / page_size)
      
      metadata = %{
        page: page,
        page_size: page_size,
        total_items: total,
        total_pages: total_pages,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
      
      Logger.info("Registros de {{SINGULAR_NAME}} recuperados com sucesso.", module: __MODULE__)
      {:ok, %{items: items, metadata: metadata}}
    else
      {:error, reason} ->
        Logger.error("Falha ao buscar registros de {{SINGULAR_NAME}} por #{field}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca registros de {{SINGULAR_NAME}} com filtros avançados.

  ## Parâmetros
    - `filters`: Mapa com os filtros a serem aplicados
    - `opts`: Mapa de opções
      - `:page` - Número da página para paginação (padrão: 1)
      - `:page_size` - Tamanho da página (padrão: 20)
      - `:order_by` - Campo para ordenação (padrão: "id")
      - `:order_direction` - Direção da ordenação ("asc" ou "desc", padrão: "asc")

  ## Retorno
    - Lista de mapas representando os registros encontrados
    - Metadados de paginação
  """
  @spec search(map(), map()) :: {:ok, %{items: [map()], metadata: map()}} | {:error, any()}
  def search(filters \\ %{}, opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    page_size = Map.get(opts, :page_size, 20)
    order_by = Map.get(opts, :order_by, "id")
    order_direction = Map.get(opts, :order_direction, "asc")
    
    offset = (page - 1) * page_size
    
    Logger.info("Buscando {{SINGULAR_NAME}}s com filtros (página #{page}, #{page_size} por página)...", module: __MODULE__)

    # Construir cláusula WHERE baseada nos filtros
    {where_clause, params} = build_where_clause(filters)
    where_str = if where_clause == "", do: "", else: "WHERE #{where_clause}"
    
    # Primeiro, obter contagem total para paginação
    count_sql = """
    SELECT COUNT(*) as total FROM {{TABLE_NAME}} #{where_str}
    """
    
    # Consulta principal com paginação e ordenação
    sql = """
    SELECT * FROM {{TABLE_NAME}} 
    #{where_str}
    ORDER BY #{order_by} #{order_direction}
    LIMIT ? OFFSET ?
    """

    all_params = params ++ [page_size, offset]

    with {:ok, %{rows: [[total]]}} <- Repo.execute(count_sql, params),
         {:ok, %{rows: rows, columns: columns}} <- Repo.execute(sql, all_params) do
      
      items = Enum.map(rows, fn row ->
        Enum.zip(columns, row) |> Enum.into(%{})
      end)
      
      total_pages = ceil(total / page_size)
      
      metadata = %{
        page: page,
        page_size: page_size,
        total_items: total,
        total_pages: total_pages,
        has_next_page: page < total_pages,
        has_prev_page: page > 1
      }
      
      Logger.info("Registros de {{SINGULAR_NAME}} recuperados com sucesso.", module: __MODULE__)
      {:ok, %{items: items, metadata: metadata}}
    else
      {:error, reason} ->
        Logger.error("Falha ao buscar registros de {{SINGULAR_NAME}} com filtros: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  # Função auxiliar para construir cláusula WHERE a partir de filtros
  defp build_where_clause(filters) do
    filters
    |> Enum.reduce({[], []}, fn {field, value}, {clauses, params} ->
      {["#{field} = ?" | clauses], [value | params]}
    end)
    |> then(fn {clauses, params} -> 
      {Enum.join(clauses, " AND "), Enum.reverse(params)}
    end)
  end
end
