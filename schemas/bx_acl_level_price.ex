defmodule DeeperHub.Schema.BxAclLevelPrice do
  @moduledoc """
  Schema para representação de bx_acl_level_prices no sistema

  Este schema armazena as informações de um bx_acl_level_price.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_acl_level_prices" do
    field :level_id, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(128)
    field :period, :integer, default: 1  # int(11) unsigned
    field :period_unit, :string, default: ""  # varchar(32)
    field :trial, :integer, default: 0  # int(11) unsigned
    field :price, :float, default: 1  # float unsigned
    field :immediate, :integer, default: 1  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_acl_level_price no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    level_id: integer() | nil,
    name: String.t() | nil,
    period: integer() | nil,
    period_unit: String.t() | nil,
    trial: integer() | nil,
    price: float() | nil,
    immediate: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_acl_level_price.

  ## Parâmetros 
    - `bx_acl_level_price`: Struct do bx_acl_level_price (pode ser %BxAclLevelPrice{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_acl_level_price \ %__MODULE__{}, attrs) do
    bx_acl_level_price
    |> cast(attrs, [:level_id, :name, :period, :period_unit, :trial, :price, :immediate, :order])
    |> validate_required([:name, :period_unit, :order])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_acl_level_price existente.

  ## Parâmetros 
    - `bx_acl_level_price`: Struct do bx_acl_level_price (%BxAclLevelPrice{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_acl_level_price \ %__MODULE__{}, attrs) do
    bx_acl_level_price
    |> cast(attrs, [:level_id, :name, :period, :period_unit, :trial, :price, :immediate, :order])
    |> unique_constraint(:name)
  end
end
