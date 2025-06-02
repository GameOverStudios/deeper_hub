defmodule DeeperHub.Schema.BxPhotosEntrie do
  @moduledoc """
  Schema para representação de bx_photos_entries no sistema

  Este schema armazena as informações de um bx_photos_entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_photos_entries" do
    field :author, :integer, default: 0  # int(10) unsigned
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :thumb, :integer, default: 0  # int(11)
    field :title, :string  # varchar(255)
    field :cat, :integer  # int(11)
    field :text, :string  # text
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
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :cf, :integer, default: 1  # int(11)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')
    field :exif, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_photos_entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    thumb: integer() | nil,
    title: String.t() | nil,
    cat: integer() | nil,
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
    allow_view_to: String.t() | nil,
    cf: integer() | nil,
    status: :active | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    exif: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_photos_entrie.

  ## Parâmetros 
    - `bx_photos_entrie`: Struct do bx_photos_entrie (pode ser %BxPhotosEntrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_photos_entrie \ %__MODULE__{}, attrs) do
    bx_photos_entrie
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :cat, :text, :labels, :location, :views, :rate, :votes, :srate, :svotes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :allow_view_to, :cf, :status, :status_admin, :exif])
    |> validate_required([:title, :cat, :text, :labels, :location, :exif])
  end

  @doc """
  Changeset para atualização de um bx_photos_entrie existente.

  ## Parâmetros 
    - `bx_photos_entrie`: Struct do bx_photos_entrie (%BxPhotosEntrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_photos_entrie \ %__MODULE__{}, attrs) do
    bx_photos_entrie
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :cat, :text, :labels, :location, :views, :rate, :votes, :srate, :svotes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :allow_view_to, :cf, :status, :status_admin, :exif])
  end
end
