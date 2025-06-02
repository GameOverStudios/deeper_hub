defmodule DeeperHub.Schema.BxAdsOffer do
  @moduledoc """
  Schema para representação de bx_ads_offers no sistema

  Este schema armazena as informações de um bx_ads_offer.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_offers" do
    field :content_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :amount, :float, default: 0  # float
    field :quantity, :integer, default: 0  # int(11)
    field :message, :string  # text
    field :status, Ecto.Enum, values: [:accepted, :awaiting, :declined, :canceled, :paid], default: "awaiting"  # enum('accepted','awaiting','declined','canceled','paid')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_offer no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    author_id: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    amount: float() | nil,
    quantity: integer() | nil,
    message: String.t() | nil,
    status: :accepted | :awaiting | :declined | :canceled | :paid | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_offer.

  ## Parâmetros 
    - `bx_ads_offer`: Struct do bx_ads_offer (pode ser %BxAdsOffer{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_offer \ %__MODULE__{}, attrs) do
    bx_ads_offer
    |> cast(attrs, [:content_id, :author_id, :added, :changed, :amount, :quantity, :message, :status])
    |> validate_required([:message])
  end

  @doc """
  Changeset para atualização de um bx_ads_offer existente.

  ## Parâmetros 
    - `bx_ads_offer`: Struct do bx_ads_offer (%BxAdsOffer{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_offer \ %__MODULE__{}, attrs) do
    bx_ads_offer
    |> cast(attrs, [:content_id, :author_id, :added, :changed, :amount, :quantity, :message, :status])
  end
end
