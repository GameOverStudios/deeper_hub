defmodule DeeperHub.Schema.BxTimelineEfVideo do
  @moduledoc """
  Schema para representação de bx_timeline_ef_videos no sistema

  Este schema armazena as informações de um bx_timeline_ef_video.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_ef_videos" do
    field :event_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_ef_video no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_ef_video.

  ## Parâmetros 
    - `bx_timeline_ef_video`: Struct do bx_timeline_ef_video (pode ser %BxTimelineEfVideo{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_ef_video \ %__MODULE__{}, attrs) do
    bx_timeline_ef_video
    |> cast(attrs, [:event_id])
  end

  @doc """
  Changeset para atualização de um bx_timeline_ef_video existente.

  ## Parâmetros 
    - `bx_timeline_ef_video`: Struct do bx_timeline_ef_video (%BxTimelineEfVideo{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_ef_video \ %__MODULE__{}, attrs) do
    bx_timeline_ef_video
    |> cast(attrs, [:event_id])
  end
end
