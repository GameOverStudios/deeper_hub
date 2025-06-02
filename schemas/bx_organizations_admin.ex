defmodule DeeperHub.Schema.BxOrganizationsAdmin do
  @moduledoc """
  Schema para representação de bx_organizations_admins no sistema

  Este schema armazena as informações de um bx_organizations_admin.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_organizations_admins" do
    field :group_profile_id, :integer  # int(10) unsigned
    field :fan_id, :integer  # int(10) unsigned
    field :role, :integer, default: 0  # int(10) unsigned
    field :order, :string, default: ""  # varchar(32)
    field :added, :integer, default: 0  # int(11) unsigned
    field :expired, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_organizations_admin no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group_profile_id: integer() | nil,
    fan_id: integer() | nil,
    role: integer() | nil,
    order: String.t() | nil,
    added: integer() | nil,
    expired: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_organizations_admin.

  ## Parâmetros 
    - `bx_organizations_admin`: Struct do bx_organizations_admin (pode ser %BxOrganizationsAdmin{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_organizations_admin \ %__MODULE__{}, attrs) do
    bx_organizations_admin
    |> cast(attrs, [:group_profile_id, :fan_id, :role, :order, :added, :expired])
    |> validate_required([:group_profile_id, :fan_id, :order])
  end

  @doc """
  Changeset para atualização de um bx_organizations_admin existente.

  ## Parâmetros 
    - `bx_organizations_admin`: Struct do bx_organizations_admin (%BxOrganizationsAdmin{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_organizations_admin \ %__MODULE__{}, attrs) do
    bx_organizations_admin
    |> cast(attrs, [:group_profile_id, :fan_id, :role, :order, :added, :expired])
  end
end
