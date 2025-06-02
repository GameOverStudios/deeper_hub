defmodule DeeperHub.Schema.BxNotificationsEvent do
  @moduledoc """
  Schema para representação de bx_notifications_events no sistema

  Este schema armazena as informações de um bx_notifications_event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_events" do
    field :owner_id, :integer, default: 0  # int(11)
    field :type, :string  # varchar(255)
    field :action, :string  # varchar(255)
    field :object_id, :string  # text
    field :object_owner_id, :integer, default: 0  # int(11)
    field :object_privacy_view, :string, default: "3"  # varchar(32)
    field :subobject_id, :integer, default: 0  # int(11)
    field :content, :string  # text
    field :source, :string, default: ""  # varchar(32)
    field :allow_view_event_to, :string, default: "3"  # varchar(32)
    field :date, :integer, default: 0  # int(11)
    field :processed, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_event no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    owner_id: integer() | nil,
    type: String.t() | nil,
    action: String.t() | nil,
    object_id: String.t() | nil,
    object_owner_id: integer() | nil,
    object_privacy_view: String.t() | nil,
    subobject_id: integer() | nil,
    content: String.t() | nil,
    source: String.t() | nil,
    allow_view_event_to: String.t() | nil,
    date: integer() | nil,
    processed: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_event.

  ## Parâmetros 
    - `bx_notifications_event`: Struct do bx_notifications_event (pode ser %BxNotificationsEvent{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_event \ %__MODULE__{}, attrs) do
    bx_notifications_event
    |> cast(attrs, [:owner_id, :type, :action, :object_id, :object_owner_id, :object_privacy_view, :subobject_id, :content, :source, :allow_view_event_to, :date, :processed, :active])
    |> validate_required([:type, :action, :object_id, :content, :source])
  end

  @doc """
  Changeset para atualização de um bx_notifications_event existente.

  ## Parâmetros 
    - `bx_notifications_event`: Struct do bx_notifications_event (%BxNotificationsEvent{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_event \ %__MODULE__{}, attrs) do
    bx_notifications_event
    |> cast(attrs, [:owner_id, :type, :action, :object_id, :object_owner_id, :object_privacy_view, :subobject_id, :content, :source, :allow_view_event_to, :date, :processed, :active])
  end
end
