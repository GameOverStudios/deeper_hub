defmodule DeeperHub.Schema.BxAdsPromoLicensesDeleted do
  @moduledoc """
  Schema para representação de bx_ads_promo_licenses_deleteds no sistema

  Este schema armazena as informações de um bx_ads_promo_licenses_deleted.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_promo_licenses_deleted" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :commodity_id, :integer, default: 0  # int(11) unsigned
    field :entry_id, :integer, default: 0  # int(11) unsigned
    field :amount, :float, default: 0  # float
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :added, :integer, default: 0  # int(11) unsigned
    field :reason, :string, default: ""  # varchar(16)
    field :deleted, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_promo_licenses_deleted no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    commodity_id: integer() | nil,
    entry_id: integer() | nil,
    amount: float() | nil,
    order: String.t() | nil,
    license: String.t() | nil,
    added: integer() | nil,
    reason: String.t() | nil,
    deleted: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_promo_licenses_deleted.

  ## Parâmetros 
    - `bx_ads_promo_licenses_deleted`: Struct do bx_ads_promo_licenses_deleted (pode ser %BxAdsPromoLicensesDeleted{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_promo_licenses_deleted \ %__MODULE__{}, attrs) do
    bx_ads_promo_licenses_deleted
    |> cast(attrs, [:profile_id, :commodity_id, :entry_id, :amount, :order, :license, :added, :reason, :deleted])
    |> validate_required([:order, :license, :reason])
  end

  @doc """
  Changeset para atualização de um bx_ads_promo_licenses_deleted existente.

  ## Parâmetros 
    - `bx_ads_promo_licenses_deleted`: Struct do bx_ads_promo_licenses_deleted (%BxAdsPromoLicensesDeleted{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_promo_licenses_deleted \ %__MODULE__{}, attrs) do
    bx_ads_promo_licenses_deleted
    |> cast(attrs, [:profile_id, :commodity_id, :entry_id, :amount, :order, :license, :added, :reason, :deleted])
  end
end
