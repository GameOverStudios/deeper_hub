defmodule DeeperHub.Schema.BxNotificationsHandler do
  @moduledoc """
  Schema para representação de bx_notifications_handlers no sistema

  Este schema armazena as informações de um bx_notifications_handler.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_handlers" do
    field :group, :string, default: ""  # varchar(64)
    field :type, Ecto.Enum, values: [:insert, :update, :delete], default: "insert"  # enum('insert','update','delete')
    field :alert_unit, :string, default: ""  # varchar(64)
    field :alert_action, :string, default: ""  # varchar(64)
    field :content, :string  # text
    field :privacy, :string, default: ""  # varchar(64)
    field :priority, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_handler no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group: String.t() | nil,
    type: :insert | :update | :delete | nil,
    alert_unit: String.t() | nil,
    alert_action: String.t() | nil,
    content: String.t() | nil,
    privacy: String.t() | nil,
    priority: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_handler.

  ## Parâmetros 
    - `bx_notifications_handler`: Struct do bx_notifications_handler (pode ser %BxNotificationsHandler{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_handler \ %__MODULE__{}, attrs) do
    bx_notifications_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :content, :privacy, :priority])
    |> validate_required([:group, :alert_unit, :alert_action, :content, :privacy])
  end

  @doc """
  Changeset para atualização de um bx_notifications_handler existente.

  ## Parâmetros 
    - `bx_notifications_handler`: Struct do bx_notifications_handler (%BxNotificationsHandler{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_handler \ %__MODULE__{}, attrs) do
    bx_notifications_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :content, :privacy, :priority])
  end
end
