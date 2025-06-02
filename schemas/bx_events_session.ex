defmodule DeeperHub.Schema.BxEventsSession do
  @moduledoc """
  Schema para representação de bx_events_sessions no sistema

  Este schema armazena as informações de um bx_events_session.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_events_sessions" do
    field :event_id, :integer, default: 0  # int(10) unsigned
    field :added, :integer, default: 0  # int(11)
    field :title, :string, default: ""  # varchar(255)
    field :description, :string  # text
    field :date_start, :integer  # int(11)
    field :date_end, :integer  # int(11)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_events_session no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    event_id: integer() | nil,
    added: integer() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    date_start: integer() | nil,
    date_end: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_events_session.

  ## Parâmetros 
    - `bx_events_session`: Struct do bx_events_session (pode ser %BxEventsSession{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_events_session \ %__MODULE__{}, attrs) do
    bx_events_session
    |> cast(attrs, [:event_id, :added, :title, :description, :date_start, :date_end, :order])
    |> validate_required([:title, :description])
  end

  @doc """
  Changeset para atualização de um bx_events_session existente.

  ## Parâmetros 
    - `bx_events_session`: Struct do bx_events_session (%BxEventsSession{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_events_session \ %__MODULE__{}, attrs) do
    bx_events_session
    |> cast(attrs, [:event_id, :added, :title, :description, :date_start, :date_end, :order])
  end
end
