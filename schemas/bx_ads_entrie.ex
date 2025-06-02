defmodule DeeperHub.Schema.BxAdsEntrie do
  @moduledoc """
  Schema para representação de bx_ads_entries no sistema

  Este schema armazena as informações de um bx_ads_entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_entries" do
    field :author, :integer  # int(11)
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :sold, :integer  # int(11)
    field :shipped, :integer  # int(11)
    field :received, :integer  # int(11)
    field :source_type, :string, default: ""  # varchar(32)
    field :source, :string, default: ""  # varchar(255)
    field :category, :integer  # int(11)
    field :thumb, :integer  # int(11)
    field :name, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :url, :string  # varchar(255)
    field :price, :float  # float
    field :auction, :integer, default: 0  # tinyint(4)
    field :quantity, :integer, default: 1  # int(11)
    field :single, :integer, default: 1  # tinyint(4)
    field :year, :integer  # int(11)
    field :text, :string  # mediumtext
    field :notes_purchased, :string  # text
    field :labels, :string  # text
    field :tags, :string  # text
    field :location, :string  # text
    field :budget_total, :float, default: 0  # float
    field :budget_daily, :float, default: 0  # float
    field :impressions, :integer, default: 0  # int(11) unsigned
    field :clicks, :integer, default: 0  # int(11) unsigned
    field :views, :integer, default: 0  # int(11)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :rrate, :float, default: 0  # float
    field :rvotes, :integer, default: 0  # int(11)
    field :score, :integer, default: 0  # int(11)
    field :sc_up, :integer, default: 0  # int(11)
    field :sc_down, :integer, default: 0  # int(11)
    field :favorites, :integer, default: 0  # int(11)
    field :comments, :integer, default: 0  # int(11)
    field :reviews, :integer, default: 0  # int(11)
    field :reviews_avg, :float, default: 0  # float
    field :reports, :integer, default: 0  # int(11)
    field :featured, :integer, default: 0  # int(11)
    field :seg, :integer, default: 0  # tinyint(4)
    field :seg_gender, :integer, default: 0  # tinyint(4)
    field :seg_age_min, :integer, default: 0  # int(11)
    field :seg_age_max, :integer, default: 0  # int(11)
    field :seg_tags, :integer, default: 0  # tinyint(4)
    field :seg_country, :string, default: ""  # varchar(255)
    field :cf, :integer, default: 1  # int(11)
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :status, Ecto.Enum, values: [:active, :awaiting, :offer, :sold, :hidden], default: "active"  # enum('active','awaiting','offer','sold','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending, :unpaid], default: "active"  # enum('active','hidden','pending','unpaid')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    sold: integer() | nil,
    shipped: integer() | nil,
    received: integer() | nil,
    source_type: String.t() | nil,
    source: String.t() | nil,
    category: integer() | nil,
    thumb: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    url: String.t() | nil,
    price: float() | nil,
    auction: integer() | nil,
    quantity: integer() | nil,
    single: integer() | nil,
    year: integer() | nil,
    text: String.t() | nil,
    notes_purchased: String.t() | nil,
    labels: String.t() | nil,
    tags: String.t() | nil,
    location: String.t() | nil,
    budget_total: float() | nil,
    budget_daily: float() | nil,
    impressions: integer() | nil,
    clicks: integer() | nil,
    views: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    rrate: float() | nil,
    rvotes: integer() | nil,
    score: integer() | nil,
    sc_up: integer() | nil,
    sc_down: integer() | nil,
    favorites: integer() | nil,
    comments: integer() | nil,
    reviews: integer() | nil,
    reviews_avg: float() | nil,
    reports: integer() | nil,
    featured: integer() | nil,
    seg: integer() | nil,
    seg_gender: integer() | nil,
    seg_age_min: integer() | nil,
    seg_age_max: integer() | nil,
    seg_tags: integer() | nil,
    seg_country: String.t() | nil,
    cf: integer() | nil,
    allow_view_to: String.t() | nil,
    status: :active | :awaiting | :offer | :sold | :hidden | nil,
    status_admin: :active | :hidden | :pending | :unpaid | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_entrie.

  ## Parâmetros 
    - `bx_ads_entrie`: Struct do bx_ads_entrie (pode ser %BxAdsEntrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_entrie \ %__MODULE__{}, attrs) do
    bx_ads_entrie
    |> cast(attrs, [:author, :added, :changed, :sold, :shipped, :received, :source_type, :source, :category, :thumb, :name, :title, :url, :price, :auction, :quantity, :single, :year, :text, :notes_purchased, :labels, :tags, :location, :budget_total, :budget_daily, :impressions, :clicks, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reviews, :reviews_avg, :reports, :featured, :seg, :seg_gender, :seg_age_min, :seg_age_max, :seg_tags, :seg_country, :cf, :allow_view_to, :status, :status_admin])
    |> validate_required([:author, :added, :changed, :sold, :shipped, :received, :source_type, :source, :category, :thumb, :name, :title, :url, :price, :year, :text, :notes_purchased, :labels, :tags, :location, :seg_country])
  end

  @doc """
  Changeset para atualização de um bx_ads_entrie existente.

  ## Parâmetros 
    - `bx_ads_entrie`: Struct do bx_ads_entrie (%BxAdsEntrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_entrie \ %__MODULE__{}, attrs) do
    bx_ads_entrie
    |> cast(attrs, [:author, :added, :changed, :sold, :shipped, :received, :source_type, :source, :category, :thumb, :name, :title, :url, :price, :auction, :quantity, :single, :year, :text, :notes_purchased, :labels, :tags, :location, :budget_total, :budget_daily, :impressions, :clicks, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reviews, :reviews_avg, :reports, :featured, :seg, :seg_gender, :seg_age_min, :seg_age_max, :seg_tags, :seg_country, :cf, :allow_view_to, :status, :status_admin])
  end
end
