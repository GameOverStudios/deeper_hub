defmodule DeeperHub.Schema.SysGridField do
  @moduledoc """
  Schema para representação de sys_grid_fields no sistema

  Este schema armazena as informações de um sys_grid_field.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_grid_fields" do
    field :object, :string  # varchar(64)
    field :name, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :width, :string  # varchar(16)
    field :translatable, :integer, default: 0  # tinyint(4)
    field :chars_limit, :integer, default: 0  # int(11)
    field :params, :string  # text
    field :hidden_on, :string, default: ""  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_grid_field no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    width: String.t() | nil,
    translatable: integer() | nil,
    chars_limit: integer() | nil,
    params: String.t() | nil,
    hidden_on: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_grid_field.

  ## Parâmetros 
    - `sys_grid_field`: Struct do sys_grid_field (pode ser %SysGridField{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_grid_field \ %__MODULE__{}, attrs) do
    sys_grid_field
    |> cast(attrs, [:object, :name, :title, :width, :translatable, :chars_limit, :params, :hidden_on, :order])
    |> validate_required([:object, :name, :title, :width, :params, :hidden_on, :order])
  end

  @doc """
  Changeset para atualização de um sys_grid_field existente.

  ## Parâmetros 
    - `sys_grid_field`: Struct do sys_grid_field (%SysGridField{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_grid_field \ %__MODULE__{}, attrs) do
    sys_grid_field
    |> cast(attrs, [:object, :name, :title, :width, :translatable, :chars_limit, :params, :hidden_on, :order])
  end
end
