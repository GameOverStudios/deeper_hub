defmodule DeeperHub.Schema.BxTimelineEfPhoto do
  @moduledoc """
  Schema para representação de bx_timeline_ef_photos no sistema

  Este schema armazena as informações de um bx_timeline_ef_photo.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_ef_photos" do
    field :event_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_ef_photo no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_ef_photo.

  ## Parâmetros 
    - `bx_timeline_ef_photo`: Struct do bx_timeline_ef_photo (pode ser %BxTimelineEfPhoto{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_ef_photo \ %__MODULE__{}, attrs) do
    bx_timeline_ef_photo
    |> cast(attrs, [:event_id])
  end

  @doc """
  Changeset para atualização de um bx_timeline_ef_photo existente.

  ## Parâmetros 
    - `bx_timeline_ef_photo`: Struct do bx_timeline_ef_photo (%BxTimelineEfPhoto{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_ef_photo \ %__MODULE__{}, attrs) do
    bx_timeline_ef_photo
    |> cast(attrs, [:event_id])
  end
end
