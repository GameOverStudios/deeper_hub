defmodule DeeperHub.Schema.BxAclLicense do
  @moduledoc """
  Schema para representação de bx_acl_licenses no sistema

  Este schema armazena as informações de um bx_acl_license.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_acl_licenses" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :price_id, :integer, default: 0  # int(11) unsigned
    field :type, :string, default: "single"  # varchar(16)
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :added, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_acl_license no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    price_id: integer() | nil,
    type: String.t() | nil,
    order: String.t() | nil,
    license: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_acl_license.

  ## Parâmetros 
    - `bx_acl_license`: Struct do bx_acl_license (pode ser %BxAclLicense{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_acl_license \ %__MODULE__{}, attrs) do
    bx_acl_license
    |> cast(attrs, [:profile_id, :price_id, :type, :order, :license, :added])
    |> validate_required([:order, :license])
  end

  @doc """
  Changeset para atualização de um bx_acl_license existente.

  ## Parâmetros 
    - `bx_acl_license`: Struct do bx_acl_license (%BxAclLicense{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_acl_license \ %__MODULE__{}, attrs) do
    bx_acl_license
    |> cast(attrs, [:profile_id, :price_id, :type, :order, :license, :added])
  end
end
