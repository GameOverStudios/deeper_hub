defmodule DeeperHub.Schema.BxNotificationsRead do
  @moduledoc """
  Schema para representação de bx_notifications_reads no sistema

  Este schema armazena as informações de um bx_notifications_read.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_read" do
    field :user_id, :integer, default: 0  # int(11)
    field :event_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_read no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    user_id: integer() | nil,
    event_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_read.

  ## Parâmetros 
    - `bx_notifications_read`: Struct do bx_notifications_read (pode ser %BxNotificationsRead{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_read \ %__MODULE__{}, attrs) do
    bx_notifications_read
    |> cast(attrs, [:user_id, :event_id])
  end

  @doc """
  Changeset para atualização de um bx_notifications_read existente.

  ## Parâmetros 
    - `bx_notifications_read`: Struct do bx_notifications_read (%BxNotificationsRead{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_read \ %__MODULE__{}, attrs) do
    bx_notifications_read
    |> cast(attrs, [:user_id, :event_id])
  end
end
