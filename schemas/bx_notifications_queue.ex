defmodule DeeperHub.Schema.BxNotificationsQueue do
  @moduledoc """
  Schema para representação de bx_notifications_queues no sistema

  Este schema armazena as informações de um bx_notifications_queue.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_queue" do
    field :profile_id, :integer, default: 0  # int(11)
    field :event_id, :integer, default: 0  # int(11)
    field :delivery, :string, default: ""  # varchar(64)
    field :content, :string  # text
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_queue no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    event_id: integer() | nil,
    delivery: String.t() | nil,
    content: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_queue.

  ## Parâmetros 
    - `bx_notifications_queue`: Struct do bx_notifications_queue (pode ser %BxNotificationsQueue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_queue \ %__MODULE__{}, attrs) do
    bx_notifications_queue
    |> cast(attrs, [:profile_id, :event_id, :delivery, :content, :date])
    |> validate_required([:delivery, :content])
  end

  @doc """
  Changeset para atualização de um bx_notifications_queue existente.

  ## Parâmetros 
    - `bx_notifications_queue`: Struct do bx_notifications_queue (%BxNotificationsQueue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_queue \ %__MODULE__{}, attrs) do
    bx_notifications_queue
    |> cast(attrs, [:profile_id, :event_id, :delivery, :content, :date])
  end
end
