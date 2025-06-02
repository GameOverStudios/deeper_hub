defmodule DeeperHub.Schema.BxAdsCategorie do
  @moduledoc """
  Schema para representação de bx_ads_categories no sistema

  Este schema armazena as informações de um bx_ads_categorie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_categories" do
    field :parent_id, :integer, default: 0  # int(11) unsigned
    field :level, :integer, default: 0  # tinyint(11) unsigned
    field :type, :integer, default: 0  # int(11)
    field :name, :string, default: ""  # varchar(64)
    field :title, :string, default: ""  # varchar(255)
    field :text, :string  # text
    field :icon, :string, default: ""  # varchar(255)
    field :items, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_categorie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    parent_id: integer() | nil,
    level: integer() | nil,
    type: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    icon: String.t() | nil,
    items: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_categorie.

  ## Parâmetros 
    - `bx_ads_categorie`: Struct do bx_ads_categorie (pode ser %BxAdsCategorie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_categorie \ %__MODULE__{}, attrs) do
    bx_ads_categorie
    |> cast(attrs, [:parent_id, :level, :type, :name, :title, :text, :icon, :items, :active, :order])
    |> validate_required([:name, :title, :text, :icon])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_ads_categorie existente.

  ## Parâmetros 
    - `bx_ads_categorie`: Struct do bx_ads_categorie (%BxAdsCategorie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_categorie \ %__MODULE__{}, attrs) do
    bx_ads_categorie
    |> cast(attrs, [:parent_id, :level, :type, :name, :title, :text, :icon, :items, :active, :order])
    |> unique_constraint(:name)
  end
end
