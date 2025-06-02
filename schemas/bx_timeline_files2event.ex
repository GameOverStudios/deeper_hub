defmodule DeeperHub.Schema.BxTimelineFiles2event do
  @moduledoc """
  Schema para representação de bx_timeline_files2events no sistema

  Este schema armazena as informações de um bx_timeline_files2event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_files2events" do
    field :event_id, :integer, default: 0  # int(11)
    field :media_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_files2event no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    media_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_files2event.

  ## Parâmetros 
    - `bx_timeline_files2event`: Struct do bx_timeline_files2event (pode ser %BxTimelineFiles2event{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_files2event \ %__MODULE__{}, attrs) do
    bx_timeline_files2event
    |> cast(attrs, [:event_id, :media_id])
  end

  @doc """
  Changeset para atualização de um bx_timeline_files2event existente.

  ## Parâmetros 
    - `bx_timeline_files2event`: Struct do bx_timeline_files2event (%BxTimelineFiles2event{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_files2event \ %__MODULE__{}, attrs) do
    bx_timeline_files2event
    |> cast(attrs, [:event_id, :media_id])
  end
end
