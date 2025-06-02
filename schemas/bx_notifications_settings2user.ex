defmodule DeeperHub.Schema.BxNotificationsSettings2user do
  @moduledoc """
  Schema para representação de bx_notifications_settings2users no sistema

  Este schema armazena as informações de um bx_notifications_settings2user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_settings2users" do
    field :user_id, :integer, default: 0  # int(11)
    field :setting_id, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_settings2user no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    user_id: integer() | nil,
    setting_id: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_settings2user.

  ## Parâmetros 
    - `bx_notifications_settings2user`: Struct do bx_notifications_settings2user (pode ser %BxNotificationsSettings2user{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_settings2user \ %__MODULE__{}, attrs) do
    bx_notifications_settings2user
    |> cast(attrs, [:user_id, :setting_id, :active])
  end

  @doc """
  Changeset para atualização de um bx_notifications_settings2user existente.

  ## Parâmetros 
    - `bx_notifications_settings2user`: Struct do bx_notifications_settings2user (%BxNotificationsSettings2user{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_settings2user \ %__MODULE__{}, attrs) do
    bx_notifications_settings2user
    |> cast(attrs, [:user_id, :setting_id, :active])
  end
end
