defmodule DeeperHub.Schema.SysInjectionsAdmin do
  @moduledoc """
  Schema para representação de sys_injections_admins no sistema

  Este schema armazena as informações de um sys_injections_admin.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_injections_admin" do
    field :name, :string, default: ""  # varchar(128)
    field :page_index, :integer, default: 0  # int(11)
    field :key, :string, default: ""  # varchar(128)
    field :type, Ecto.Enum, values: [:text, :service], default: "text"  # enum('text','service')
    field :data, :string  # text
    field :replace, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_injections_admin no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    page_index: integer() | nil,
    key: String.t() | nil,
    type: :text | :service | nil,
    data: String.t() | nil,
    replace: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_injections_admin.

  ## Parâmetros 
    - `sys_injections_admin`: Struct do sys_injections_admin (pode ser %SysInjectionsAdmin{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_injections_admin \ %__MODULE__{}, attrs) do
    sys_injections_admin
    |> cast(attrs, [:name, :page_index, :key, :type, :data, :replace, :active])
    |> validate_required([:name, :key, :data])
  end

  @doc """
  Changeset para atualização de um sys_injections_admin existente.

  ## Parâmetros 
    - `sys_injections_admin`: Struct do sys_injections_admin (%SysInjectionsAdmin{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_injections_admin \ %__MODULE__{}, attrs) do
    sys_injections_admin
    |> cast(attrs, [:name, :page_index, :key, :type, :data, :replace, :active])
  end
end
