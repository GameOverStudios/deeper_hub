defmodule DeeperHub.Schema.BxTimelineLinks2event do
  @moduledoc """
  Schema para representação de bx_timeline_links2events no sistema

  Este schema armazena as informações de um bx_timeline_links2event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_links2events" do
    field :event_id, :integer, default: 0  # int(11)
    field :link_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_links2event no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    link_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_links2event.

  ## Parâmetros 
    - `bx_timeline_links2event`: Struct do bx_timeline_links2event (pode ser %BxTimelineLinks2event{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_links2event \ %__MODULE__{}, attrs) do
    bx_timeline_links2event
    |> cast(attrs, [:event_id, :link_id])
  end

  @doc """
  Changeset para atualização de um bx_timeline_links2event existente.

  ## Parâmetros 
    - `bx_timeline_links2event`: Struct do bx_timeline_links2event (%BxTimelineLinks2event{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_links2event \ %__MODULE__{}, attrs) do
    bx_timeline_links2event
    |> cast(attrs, [:event_id, :link_id])
  end
end
