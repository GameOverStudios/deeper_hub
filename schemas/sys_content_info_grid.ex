defmodule DeeperHub.Schema.SysContentInfoGrid do
  @moduledoc """
  Schema para representação de sys_content_info_grids no sistema

  Este schema armazena as informações de um sys_content_info_grid.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_content_info_grids" do
    field :object, :string  # varchar(64)
    field :grid_object, :string  # varchar(64)
    field :grid_field_id, :string  # varchar(64)
    field :condition, :string, default: "''"  # text
    field :selection, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_content_info_grid no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    grid_object: String.t() | nil,
    grid_field_id: String.t() | nil,
    condition: String.t() | nil,
    selection: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_content_info_grid.

  ## Parâmetros 
    - `sys_content_info_grid`: Struct do sys_content_info_grid (pode ser %SysContentInfoGrid{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_content_info_grid \ %__MODULE__{}, attrs) do
    sys_content_info_grid
    |> cast(attrs, [:object, :grid_object, :grid_field_id, :condition, :selection])
    |> validate_required([:object, :grid_object, :grid_field_id, :selection])
    |> unique_constraint(:grid_object)
  end

  @doc """
  Changeset para atualização de um sys_content_info_grid existente.

  ## Parâmetros 
    - `sys_content_info_grid`: Struct do sys_content_info_grid (%SysContentInfoGrid{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_content_info_grid \ %__MODULE__{}, attrs) do
    sys_content_info_grid
    |> cast(attrs, [:object, :grid_object, :grid_field_id, :condition, :selection])
    |> unique_constraint(:grid_object)
  end
end
