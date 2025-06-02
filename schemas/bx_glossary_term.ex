defmodule DeeperHub.Schema.BxGlossaryTerm do
  @moduledoc """
  Schema para representação de bx_glossary_terms no sistema

  Este schema armazena as informações de um bx_glossary_term.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_glossary_terms" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :thumb, :integer  # int(11)
    field :title, :string  # varchar(255)
    field :cat, :integer  # int(11)
    field :text, :string  # text
    field :labels, :string  # text
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
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_glossary_term no sistema
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
    status: :active | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_glossary_term.

  ## Parâmetros 
    - `bx_glossary_term`: Struct do bx_glossary_term (pode ser %BxGlossaryTerm{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_glossary_term \ %__MODULE__{}, attrs) do
    bx_glossary_term
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :cat, :text, :labels, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
    |> validate_required([:author, :added, :changed, :thumb, :title, :cat, :text, :labels])
  end

  @doc """
  Changeset para atualização de um bx_glossary_term existente.

  ## Parâmetros 
    - `bx_glossary_term`: Struct do bx_glossary_term (%BxGlossaryTerm{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_glossary_term \ %__MODULE__{}, attrs) do
    bx_glossary_term
    |> cast(attrs, [:author, :added, :changed, :thumb, :title, :cat, :text, :labels, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
  end
end
