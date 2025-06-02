defmodule DeeperHub.Schema.BxMarketLicense do
  @moduledoc """
  Schema para representação de bx_market_licenses no sistema

  Este schema armazena as informações de um bx_market_license.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_market_licenses" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :product_id, :integer, default: 0  # int(11) unsigned
    field :count, :integer, default: 0  # int(11) unsigned
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :type, :string, default: ""  # varchar(16)
    field :domain, :string, default: ""  # varchar(128)
    field :added, :integer, default: 0  # int(11) unsigned
    field :expired, :integer, default: 0  # int(11) unsigned
    field :expired_notif, :integer, default: 0  # int(11) unsigned
    field :new, :boolean, default: true  # tinyint(1)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_market_license no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    product_id: integer() | nil,
    count: integer() | nil,
    order: String.t() | nil,
    license: String.t() | nil,
    type: String.t() | nil,
    domain: String.t() | nil,
    added: integer() | nil,
    expired: integer() | nil,
    expired_notif: integer() | nil,
    new: boolean() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_market_license.

  ## Parâmetros 
    - `bx_market_license`: Struct do bx_market_license (pode ser %BxMarketLicense{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_market_license \ %__MODULE__{}, attrs) do
    bx_market_license
    |> cast(attrs, [:profile_id, :product_id, :count, :order, :license, :type, :domain, :added, :expired, :expired_notif, :new])
    |> validate_required([:order, :license, :type, :domain])
  end

  @doc """
  Changeset para atualização de um bx_market_license existente.

  ## Parâmetros 
    - `bx_market_license`: Struct do bx_market_license (%BxMarketLicense{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_market_license \ %__MODULE__{}, attrs) do
    bx_market_license
    |> cast(attrs, [:profile_id, :product_id, :count, :order, :license, :type, :domain, :added, :expired, :expired_notif, :new])
  end
end
