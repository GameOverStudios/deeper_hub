defmodule DeeperHub.Schema.BxOrganizationsData do
  @moduledoc """
  Schema para representação de bx_organizations_datas no sistema

  Este schema armazena as informações de um bx_organizations_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_organizations_data" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :picture, :integer  # int(11)
    field :cover, :integer  # int(11)
    field :cover_data, :string  # varchar(50)
    field :org_name, :string  # varchar(255)
    field :org_cat, :integer  # int(11)
    field :multicat, :string  # text
    field :org_desc, :string  # text
    field :labels, :string  # text
    field :location, :string  # text
    field :members, :integer, default: 0  # int(11)
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
    field :join_confirmation, :integer, default: 1  # tinyint(4)
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :allow_post_to, :string, default: "5"  # varchar(16)
    field :allow_contact_to, :string, default: "3"  # varchar(16)
    field :status, Ecto.Enum, values: [:active, :awaiting, :hidden], default: "active"  # enum('active','awaiting','hidden')
    field :settings, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_organizations_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    picture: integer() | nil,
    cover: integer() | nil,
    cover_data: String.t() | nil,
    org_name: String.t() | nil,
    org_cat: integer() | nil,
    multicat: String.t() | nil,
    org_desc: String.t() | nil,
    labels: String.t() | nil,
    location: String.t() | nil,
    members: integer() | nil,
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
    join_confirmation: integer() | nil,
    allow_view_to: String.t() | nil,
    allow_post_to: String.t() | nil,
    allow_contact_to: String.t() | nil,
    status: :active | :awaiting | :hidden | nil,
    settings: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_organizations_data.

  ## Parâmetros 
    - `bx_organizations_data`: Struct do bx_organizations_data (pode ser %BxOrganizationsData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_organizations_data \ %__MODULE__{}, attrs) do
    bx_organizations_data
    |> cast(attrs, [:author, :added, :changed, :picture, :cover, :cover_data, :org_name, :org_cat, :multicat, :org_desc, :labels, :location, :members, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :join_confirmation, :allow_view_to, :allow_post_to, :allow_contact_to, :status, :settings])
    |> validate_required([:author, :added, :changed, :picture, :cover, :cover_data, :org_name, :org_cat, :multicat, :org_desc, :labels, :location, :settings])
  end

  @doc """
  Changeset para atualização de um bx_organizations_data existente.

  ## Parâmetros 
    - `bx_organizations_data`: Struct do bx_organizations_data (%BxOrganizationsData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_organizations_data \ %__MODULE__{}, attrs) do
    bx_organizations_data
    |> cast(attrs, [:author, :added, :changed, :picture, :cover, :cover_data, :org_name, :org_cat, :multicat, :org_desc, :labels, :location, :members, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :join_confirmation, :allow_view_to, :allow_post_to, :allow_contact_to, :status, :settings])
  end
end
