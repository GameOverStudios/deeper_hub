defmodule DeeperHub.Schema.BxCnlData do
  @moduledoc """
  Schema para representação de bx_cnl_datas no sistema

  Este schema armazena as informações de um bx_cnl_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_cnl_data" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :picture, :integer  # int(11)
    field :cover, :integer  # int(11)
    field :cover_data, :string  # varchar(50)
    field :channel_name, :string  # varchar(191)
    field :lc_id, :integer, default: 0  # int(11)
    field :lc_date, :integer, default: 0  # int(11)
    field :contents, :integer, default: 0  # int(11)
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
    field :allow_view_to, :string, default: "3"  # varchar(255)
    field :status, Ecto.Enum, values: [:active, :awaiting, :hidden], default: "active"  # enum('active','awaiting','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_cnl_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    picture: integer() | nil,
    cover: integer() | nil,
    cover_data: String.t() | nil,
    channel_name: String.t() | nil,
    lc_id: integer() | nil,
    lc_date: integer() | nil,
    contents: integer() | nil,
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
    status: :active | :awaiting | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_cnl_data.

  ## Parâmetros 
    - `bx_cnl_data`: Struct do bx_cnl_data (pode ser %BxCnlData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_cnl_data \ %__MODULE__{}, attrs) do
    bx_cnl_data
    |> cast(attrs, [:author, :added, :changed, :picture, :cover, :cover_data, :channel_name, :lc_id, :lc_date, :contents, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
    |> validate_required([:author, :added, :changed, :picture, :cover, :cover_data, :channel_name])
    |> unique_constraint(:channel_name)
  end

  @doc """
  Changeset para atualização de um bx_cnl_data existente.

  ## Parâmetros 
    - `bx_cnl_data`: Struct do bx_cnl_data (%BxCnlData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_cnl_data \ %__MODULE__{}, attrs) do
    bx_cnl_data
    |> cast(attrs, [:author, :added, :changed, :picture, :cover, :cover_data, :channel_name, :lc_id, :lc_date, :contents, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin])
    |> unique_constraint(:channel_name)
  end
end
