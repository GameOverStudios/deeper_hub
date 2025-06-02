defmodule DeeperHub.Core.Data.Schemas.BxOrganizationsViewsTrack do
  @moduledoc """
  Este schema armazena as informações de um bx_organizations_views_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Busca todos os registros de bx_organizations_views_tracks na tabela bx_organizations_views_track.

  ## Retorno
    - Lista de mapas representando os registros
  """
  @spec all() :: {:ok, [map()]} | {:error, any()}
  def all do
    Logger.info("Buscando todos os registros de bx_organizations_views_track...", module: __MODULE__)

    sql = """
    SELECT * FROM bx_organizations_views_track
    """

    case Repo.execute(sql) do
      {:ok, %{rows: rows, columns: columns}} ->
        result = Enum.map(rows, fn row ->
          Enum.zip(columns, row) |> Enum.into(%{})
        end)
        Logger.info("Registros de bx_organizations_views_track recuperados com sucesso.", module: __MODULE__)
        {:ok, result}

      {:error, reason} ->
        Logger.error("Falha ao buscar registros de bx_organizations_views_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca um bx_organizations_views_track pelo ID.

  ## Parâmetros
    - `id`: ID do registro a ser buscado

  ## Retorno
    - Mapa representando o registro encontrado ou nil se não encontrado
  """
  @spec get(String.t()) :: {:ok, map() | nil} | {:error, any()}
  def get(id) do
    Logger.info("Buscando bx_organizations_views_track com ID: #{id}", module: __MODULE__)

    sql = """
    SELECT * FROM bx_organizations_views_track WHERE id = ?
    """

    case Repo.execute(sql, [id]) do
      {:ok, %{rows: [row], columns: columns}} ->
        result = Enum.zip(columns, row) |> Enum.into(%{})
        Logger.info("Registro de bx_organizations_views_track recuperado com sucesso.", module: __MODULE__)
        {:ok, result}

      {:ok, %{rows: []}} ->
        Logger.info("Nenhum registro de bx_organizations_views_track encontrado com ID: #{id}", module: __MODULE__)
        {:ok, nil}

      {:error, reason} ->
        Logger.error("Falha ao buscar bx_organizations_views_track com ID: #{id}, erro: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Cria um novo registro de bx_organizations_views_track.

  ## Parâmetros
    - `attrs`: Mapa com os atributos do registro a ser criado

  ## Retorno
    - ID do registro criado
  """
  @spec create(map()) :: {:ok, integer()} | {:error, any()}
  def create(attrs) do
    Logger.info("Criando novo registro de bx_organizations_views_track: #{attrs}", module: __MODULE__)

    # Preparar campos e valores
    fields = Map.keys(attrs) |> Enum.filter(&(&1 not in [:id]))
    placeholders = Enum.map(fields, fn _ -> "?" end) |> Enum.join(", ")
    values = Enum.map(fields, &Map.get(attrs, &1))
    
    fields_str = fields
      |> Enum.map(&to_string/1)
      |> Enum.join(", ")

    sql = """
    INSERT INTO bx_organizations_views_track (#{fields_str})
    VALUES (#{placeholders})
    """

    case Repo.execute(sql, values) do
      {:ok, %{last_insert_id: id}} ->
        Logger.info("Registro de bx_organizations_views_track criado com sucesso. ID: #{id}", module: __MODULE__)
        {:ok, id}

      {:error, reason} ->
        Logger.error("Falha ao criar registro de bx_organizations_views_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Atualiza um registro de bx_organizations_views_track existente.

  ## Parâmetros
    - `id`: ID do registro a ser atualizado
    - `attrs`: Mapa com os atributos a serem atualizados

  ## Retorno
    - :ok se sucesso, {:error, reason} se falha
  """
  @spec update(integer(), map()) :: :ok | {:error, any()}
  def update(id, attrs) do
    Logger.info("Atualizando registro de bx_organizations_views_track com ID: #{id}", module: __MODULE__)

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
    UPDATE bx_organizations_views_track
    SET #{update_str}
    WHERE id = ?
    """

    case Repo.execute(sql, values) do
      {:ok, %{affected_rows: 1}} ->
        Logger.info("Registro de bx_organizations_views_track atualizado com sucesso.", module: __MODULE__)
        :ok

      {:ok, %{affected_rows: 0}} ->
        Logger.info("Nenhum registro de bx_organizations_views_track encontrado com ID: #{id}", module: __MODULE__)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Falha ao atualizar registro de bx_organizations_views_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove um registro de bx_organizations_views_track.

  ## Parâmetros
    - `id`: ID do registro a ser removido

  ## Retorno
    - :ok se sucesso, {:error, reason} se falha
  """
  @spec delete(integer()) :: :ok | {:error, any()}
  def delete(id) do
    Logger.info("Excluindo registro de bx_organizations_views_track com ID: #{id}", module: __MODULE__)

    sql = """
    DELETE FROM bx_organizations_views_track
    WHERE id = ?
    """

    case Repo.execute(sql, [id]) do
      {:ok, %{affected_rows: 1}} ->
        Logger.info("Registro de bx_organizations_views_track excluído com sucesso.", module: __MODULE__)
        :ok

      {:ok, %{affected_rows: 0}} ->
        Logger.info("Nenhum registro de bx_organizations_views_track encontrado com ID: #{id}", module: __MODULE__)
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Falha ao excluir registro de bx_organizations_views_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca registros de bx_organizations_views_track por um campo específico.

  ## Parâmetros
    - `field`: Campo a ser usado na busca
    - `value`: Valor a ser buscado

  ## Retorno
    - Lista de mapas representando os registros encontrados
  """
  @spec get_by(atom(), any()) :: {:ok, [map()]} | {:error, any()}
  def get_by(field, value) do
    Logger.info("Buscando bx_organizations_views_tracks por #{field}: #{value}", module: __MODULE__)

    sql = """
    SELECT * FROM bx_organizations_views_track WHERE #{field} = ?
    """

    case Repo.execute(sql, [value]) do
      {:ok, %{rows: rows, columns: columns}} ->
        result = Enum.map(rows, fn row ->
          Enum.zip(columns, row) |> Enum.into(%{})
        end)
        Logger.info("Registros de bx_organizations_views_track recuperados com sucesso.", module: __MODULE__)
        {:ok, result}

      {:error, reason} ->
        Logger.error("Falha ao buscar registros de bx_organizations_views_track por #{field}: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
