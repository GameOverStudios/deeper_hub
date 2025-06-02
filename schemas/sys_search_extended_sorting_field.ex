defmodule DeeperHub.Schema.SysSearchExtendedSortingField do
  @moduledoc """
  Schema para representação de sys_search_extended_sorting_fields no sistema

  Este schema armazena as informações de um sys_search_extended_sorting_field.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_search_extended_sorting_fields" do
    field :object, :string, default: ""  # varchar(64)
    field :name, :string, default: ""  # varchar(255)
    field :direction, :string, default: ""  # varchar(32)
    field :caption, :string, default: ""  # varchar(255)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_search_extended_sorting_field no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    name: String.t() | nil,
    direction: String.t() | nil,
    caption: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_search_extended_sorting_field.

  ## Parâmetros 
    - `sys_search_extended_sorting_field`: Struct do sys_search_extended_sorting_field (pode ser %SysSearchExtendedSortingField{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_search_extended_sorting_field \ %__MODULE__{}, attrs) do
    sys_search_extended_sorting_field
    |> cast(attrs, [:object, :name, :direction, :caption, :active, :order])
    |> validate_required([:object, :name, :direction, :caption])
  end

  @doc """
  Changeset para atualização de um sys_search_extended_sorting_field existente.

  ## Parâmetros 
    - `sys_search_extended_sorting_field`: Struct do sys_search_extended_sorting_field (%SysSearchExtendedSortingField{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_search_extended_sorting_field \ %__MODULE__{}, attrs) do
    sys_search_extended_sorting_field
    |> cast(attrs, [:object, :name, :direction, :caption, :active, :order])
  end
end
