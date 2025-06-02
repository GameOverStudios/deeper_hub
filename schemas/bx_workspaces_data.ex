defmodule DeeperHub.Schema.BxWorkspacesData do
  @moduledoc """
  Schema para representação de bx_workspaces_datas no sistema

  Este schema armazena as informações de um bx_workspaces_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_workspaces_data" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
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
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :allow_post_to, :string, default: "5"  # varchar(16)
    field :allow_contact_to, :string, default: "3"  # varchar(16)
    field :settings, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_workspaces_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
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
    allow_view_to: String.t() | nil,
    allow_post_to: String.t() | nil,
    allow_contact_to: String.t() | nil,
    settings: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_workspaces_data.

  ## Parâmetros 
    - `bx_workspaces_data`: Struct do bx_workspaces_data (pode ser %BxWorkspacesData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_workspaces_data \ %__MODULE__{}, attrs) do
    bx_workspaces_data
    |> cast(attrs, [:author, :added, :changed, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :allow_view_to, :allow_post_to, :allow_contact_to, :settings])
    |> validate_required([:author, :added, :changed, :settings])
  end

  @doc """
  Changeset para atualização de um bx_workspaces_data existente.

  ## Parâmetros 
    - `bx_workspaces_data`: Struct do bx_workspaces_data (%BxWorkspacesData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_workspaces_data \ %__MODULE__{}, attrs) do
    bx_workspaces_data
    |> cast(attrs, [:author, :added, :changed, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :allow_view_to, :allow_post_to, :allow_contact_to, :settings])
  end
end
