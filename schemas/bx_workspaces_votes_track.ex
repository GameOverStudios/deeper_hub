defmodule DeeperHub.Schema.BxWorkspacesVotesTrack do
  @moduledoc """
  Schema para representação de bx_workspaces_votes_tracks no sistema

  Este schema armazena as informações de um bx_workspaces_votes_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_workspaces_votes_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :value, :integer, default: 0  # tinyint(4)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_workspaces_votes_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    value: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_workspaces_votes_track.

  ## Parâmetros 
    - `bx_workspaces_votes_track`: Struct do bx_workspaces_votes_track (pode ser %BxWorkspacesVotesTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_workspaces_votes_track \ %__MODULE__{}, attrs) do
    bx_workspaces_votes_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :value, :date])
  end

  @doc """
  Changeset para atualização de um bx_workspaces_votes_track existente.

  ## Parâmetros 
    - `bx_workspaces_votes_track`: Struct do bx_workspaces_votes_track (%BxWorkspacesVotesTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_workspaces_votes_track \ %__MODULE__{}, attrs) do
    bx_workspaces_votes_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :value, :date])
  end
end
