defmodule DeeperHub.Schema.BxMarketProduct do
  @moduledoc """
  Schema para representação de bx_market_products no sistema

  Este schema armazena as informações de um bx_market_product.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_market_products" do
    field :author, :integer, default: 0  # int(11) unsigned
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :thumb, :integer, default: 0  # int(11)
    field :cover, :integer, default: 0  # int(11)
    field :cover_data, :string, default: ""  # varchar(64)
    field :cover_raw, :string  # longtext
    field :package, :integer, default: 0  # int(11)
    field :name, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :text, :string  # text
    field :notes, :string  # text
    field :notes_purchased, :string  # text
    field :cat, :integer  # int(11)
    field :price_single, :float, default: 0  # float
    field :price_recurring, :float, default: 0  # float
    field :duration_recurring, :string, default: "month"  # varchar(16)
    field :trial_recurring, :integer, default: 0  # int(11)
    field :labels, :string  # text
    field :location, :string  # text
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
    field :reports, :integer, default: 0  # int(11)
    field :featured, :integer, default: 0  # int(11)
    field :cf, :integer, default: 1  # int(11)
    field :allow_view_to, :string, default: "3"  # varchar(32)
    field :allow_purchase_to, :string, default: "3"  # varchar(32)
    field :allow_comment_to, :string, default: "c"  # varchar(32)
    field :allow_vote_to, :string, default: "c"  # varchar(32)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_market_product no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    thumb: integer() | nil,
    cover: integer() | nil,
    cover_data: String.t() | nil,
    cover_raw: String.t() | nil,
    package: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    notes: String.t() | nil,
    notes_purchased: String.t() | nil,
    cat: integer() | nil,
    price_single: float() | nil,
    price_recurring: float() | nil,
    duration_recurring: String.t() | nil,
    trial_recurring: integer() | nil,
    labels: String.t() | nil,
    location: String.t() | nil,
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
    reports: integer() | nil,
    featured: integer() | nil,
    cf: integer() | nil,
    allow_view_to: String.t() | nil,
    allow_purchase_to: String.t() | nil,
    allow_comment_to: String.t() | nil,
    allow_vote_to: String.t() | nil,
    status: :active | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_market_product.

  ## Parâmetros 
    - `bx_market_product`: Struct do bx_market_product (pode ser %BxMarketProduct{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_market_product \ %__MODULE__{}, attrs) do
    bx_market_product
    |> cast(attrs, [:author, :added, :changed, :thumb, :cover, :cover_data, :cover_raw, :package, :name, :title, :text, :notes, :notes_purchased, :cat, :price_single, :price_recurring, :duration_recurring, :trial_recurring, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :allow_purchase_to, :allow_comment_to, :allow_vote_to, :status, :status_admin])
    |> validate_required([:cover_data, :cover_raw, :name, :title, :text, :notes, :notes_purchased, :cat, :labels, :location])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_market_product existente.

  ## Parâmetros 
    - `bx_market_product`: Struct do bx_market_product (%BxMarketProduct{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_market_product \ %__MODULE__{}, attrs) do
    bx_market_product
    |> cast(attrs, [:author, :added, :changed, :thumb, :cover, :cover_data, :cover_raw, :package, :name, :title, :text, :notes, :notes_purchased, :cat, :price_single, :price_recurring, :duration_recurring, :trial_recurring, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :allow_purchase_to, :allow_comment_to, :allow_vote_to, :status, :status_admin])
    |> unique_constraint(:name)
  end
end
