defmodule DeeperHub.Schema.SysSearchExtendedField do
  @moduledoc """
  Schema para representação de sys_search_extended_fields no sistema

  Este schema armazena as informações de um sys_search_extended_field.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_search_extended_fields" do
    field :object, :string, default: ""  # varchar(64)
    field :name, :string, default: ""  # varchar(255)
    field :type, :string, default: ""  # varchar(32)
    field :caption, :string, default: ""  # varchar(255)
    field :info, :string, default: ""  # varchar(255)
    field :values, :string, default: "''"  # text
    field :pass, :string  # varchar(32)
    field :search_type, :string, default: ""  # varchar(32)
    field :search_value, :string, default: ""  # varchar(255)
    field :search_operator, :string, default: ""  # varchar(32)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_search_extended_field no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    name: String.t() | nil,
    type: String.t() | nil,
    caption: String.t() | nil,
    info: String.t() | nil,
    values: String.t() | nil,
    pass: String.t() | nil,
    search_type: String.t() | nil,
    search_value: String.t() | nil,
    search_operator: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_search_extended_field.

  ## Parâmetros 
    - `sys_search_extended_field`: Struct do sys_search_extended_field (pode ser %SysSearchExtendedField{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_search_extended_field \ %__MODULE__{}, attrs) do
    sys_search_extended_field
    |> cast(attrs, [:object, :name, :type, :caption, :info, :values, :pass, :search_type, :search_value, :search_operator, :active, :order])
    |> validate_required([:object, :name, :type, :caption, :info, :pass, :search_type, :search_value, :search_operator])
  end

  @doc """
  Changeset para atualização de um sys_search_extended_field existente.

  ## Parâmetros 
    - `sys_search_extended_field`: Struct do sys_search_extended_field (%SysSearchExtendedField{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_search_extended_field \ %__MODULE__{}, attrs) do
    sys_search_extended_field
    |> cast(attrs, [:object, :name, :type, :caption, :info, :values, :pass, :search_type, :search_value, :search_operator, :active, :order])
  end
end
