defmodule DeeperHub.Schema.BxAdsPromoTracker do
  @moduledoc """
  Schema para representação de bx_ads_promo_trackers no sistema

  Este schema armazena as informações de um bx_ads_promo_tracker.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_promo_tracker" do
    field :entry_id, :integer, default: 0  # int(11) unsigned
    field :date, :integer, default: 0  # int(11) unsigned
    field :impressions, :integer, default: 0  # int(11) unsigned
    field :clicks, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_promo_tracker no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    date: integer() | nil,
    impressions: integer() | nil,
    clicks: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_promo_tracker.

  ## Parâmetros 
    - `bx_ads_promo_tracker`: Struct do bx_ads_promo_tracker (pode ser %BxAdsPromoTracker{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_promo_tracker \ %__MODULE__{}, attrs) do
    bx_ads_promo_tracker
    |> cast(attrs, [:entry_id, :date, :impressions, :clicks])
  end

  @doc """
  Changeset para atualização de um bx_ads_promo_tracker existente.

  ## Parâmetros 
    - `bx_ads_promo_tracker`: Struct do bx_ads_promo_tracker (%BxAdsPromoTracker{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_promo_tracker \ %__MODULE__{}, attrs) do
    bx_ads_promo_tracker
    |> cast(attrs, [:entry_id, :date, :impressions, :clicks])
  end
end
