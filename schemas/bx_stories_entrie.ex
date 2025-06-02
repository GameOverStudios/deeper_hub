defmodule DeeperHub.Schema.BxStoriesEntrie do
  @moduledoc """
  Schema para representação de bx_stories_entries no sistema

  Este schema armazena as informações de um bx_stories_entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_stories_entries" do
    field :author, :integer  # int(11) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :expired, :integer  # int(11)
    field :thumb, :integer  # int(11)
    field :title, :string  # varchar(255)
    field :text, :string  # text
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
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :status, Ecto.Enum, values: [:active, :awaiting, :failed, :hidden], default: "active"  # enum('active','awaiting','failed','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_stories_entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    expired: integer() | nil,
    thumb: integer() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
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
    status: :active | :awaiting | :failed | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_stories_entrie.

  ## Parâmetros 
    - `bx_stories_entrie`: Struct do bx_stories_entrie (pode ser %BxStoriesEntrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_stories_entrie \ %__MODULE__{}, attrs) do
    bx_stories_entrie
    |> cast(attrs, [:author, :added, :changed, :expired, :thumb, :title, :text, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
    |> validate_required([:author, :added, :changed, :expired, :thumb, :title, :text, :labels, :location])
  end

  @doc """
  Changeset para atualização de um bx_stories_entrie existente.

  ## Parâmetros 
    - `bx_stories_entrie`: Struct do bx_stories_entrie (%BxStoriesEntrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_stories_entrie \ %__MODULE__{}, attrs) do
    bx_stories_entrie
    |> cast(attrs, [:author, :added, :changed, :expired, :thumb, :title, :text, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
  end
end
