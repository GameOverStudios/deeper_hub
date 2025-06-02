defmodule DeeperHub.Schema.BxTimelineHotTrack do
  @moduledoc """
  Schema para representação de bx_timeline_hot_tracks no sistema

  Este schema armazena as informações de um bx_timeline_hot_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_hot_track" do
    field :event_id, :integer, default: 0  # int(11)
    field :value, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_hot_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    value: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_hot_track.

  ## Parâmetros 
    - `bx_timeline_hot_track`: Struct do bx_timeline_hot_track (pode ser %BxTimelineHotTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_hot_track \ %__MODULE__{}, attrs) do
    bx_timeline_hot_track
    |> cast(attrs, [:event_id, :value])
    |> unique_constraint(:event_id)
  end

  @doc """
  Changeset para atualização de um bx_timeline_hot_track existente.

  ## Parâmetros 
    - `bx_timeline_hot_track`: Struct do bx_timeline_hot_track (%BxTimelineHotTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_hot_track \ %__MODULE__{}, attrs) do
    bx_timeline_hot_track
    |> cast(attrs, [:event_id, :value])
    |> unique_constraint(:event_id)
  end
end
