defmodule DeeperHub.Schema.BxReviewsReview do
  @moduledoc """
  Schema para representação de bx_reviews_reviews no sistema

  Este schema armazena as informações de um bx_reviews_review.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reviews_reviews" do
    field :author, :integer  # int(11)
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :thumb, :integer  # int(11)
    field :title, :string  # varchar(255)
    field :voting_options, :string  # text
    field :voting_avg, :float  # float
    field :cat, :integer  # int(11)
    field :multicat, :string  # text
    field :text, :string  # mediumtext
    field :labels, :string  # text
    field :location, :string  # text
    field :views, :integer, default: 0  # int(11)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :srate, :float, default: 0  # float
    field :svotes, :integer, default: 0  # int(11)
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
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :reviewed_profile, :integer, default: 0  # int(11)
    field :product, :string  # varchar(255)
    field :allow_comments, :integer, default: 1  # tinyint(4)
    field :status, Ecto.Enum, values: [:active, :awaiting, :failed, :hidden], default: "active"  # enum('active','awaiting','failed','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reviews_review no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    thumb: integer() | nil,
    title: String.t() | nil,
    voting_options: String.t() | nil,
    voting_avg: float() | nil,
    cat: integer() | nil,
    multicat: String.t() | nil,
    text: String.t() | nil,
    labels: String.t() | nil,
    location: String.t() | nil,
    views: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    srate: float() | nil,
    svotes: integer() | nil,
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
    reviewed_profile: integer() | nil,
    product: String.t() | nil,
    allow_comments: integer() | nil,
    status: :active | :awaiting | :failed | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reviews_review.

  ## Parâmetros 
    - `bx_reviews_review`: Struct do bx_reviews_review (pode ser %BxReviewsReview{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reviews_review \ %__MODULE__{}, attrs) do
    bx_reviews_review
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :voting_options, :voting_avg, :cat, :multicat, :text, :labels, :location, :views, :rate, :votes, :srate, :svotes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :reviewed_profile, :product, :allow_comments, :status, :status_admin])
    |> validate_required([:author, :added, :changed, :thumb, :title, :voting_options, :voting_avg, :cat, :multicat, :text, :labels, :location, :product])
  end

  @doc """
  Changeset para atualização de um bx_reviews_review existente.

  ## Parâmetros 
    - `bx_reviews_review`: Struct do bx_reviews_review (%BxReviewsReview{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reviews_review \ %__MODULE__{}, attrs) do
    bx_reviews_review
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :voting_options, :voting_avg, :cat, :multicat, :text, :labels, :location, :views, :rate, :votes, :srate, :svotes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :reviewed_profile, :product, :allow_comments, :status, :status_admin])
  end
end
