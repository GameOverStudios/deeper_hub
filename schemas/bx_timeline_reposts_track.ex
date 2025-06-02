defmodule DeeperHub.Schema.BxTimelineRepostsTrack do
  @moduledoc """
  Schema para representação de bx_timeline_reposts_tracks no sistema

  Este schema armazena as informações de um bx_timeline_reposts_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_reposts_track" do
    field :event_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :reposted_id, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_reposts_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    reposted_id: integer() | nil,
    date: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_reposts_track.

  ## Parâmetros 
    - `bx_timeline_reposts_track`: Struct do bx_timeline_reposts_track (pode ser %BxTimelineRepostsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_reposts_track \ %__MODULE__{}, attrs) do
    bx_timeline_reposts_track
    |> cast(attrs, [:event_id, :author_id, :author_nip, :reposted_id, :date, :active])
    |> unique_constraint(:event_id)
  end

  @doc """
  Changeset para atualização de um bx_timeline_reposts_track existente.

  ## Parâmetros 
    - `bx_timeline_reposts_track`: Struct do bx_timeline_reposts_track (%BxTimelineRepostsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_reposts_track \ %__MODULE__{}, attrs) do
    bx_timeline_reposts_track
    |> cast(attrs, [:event_id, :author_id, :author_nip, :reposted_id, :date, :active])
    |> unique_constraint(:event_id)
  end
end
