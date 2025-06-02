defmodule DeeperHub.Schema.BxNotificationsSetting do
  @moduledoc """
  Schema para representação de bx_notifications_settings no sistema

  Este schema armazena as informações de um bx_notifications_setting.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_notifications_settings" do
    field :group, :string, default: ""  # varchar(64)
    field :handler_id, :integer, default: 0  # int(11)
    field :delivery, Ecto.Enum, values: [:site, :email, :push], default: "site"  # enum('site','email','push')
    field :type, Ecto.Enum, values: [:personal, :follow_member, :follow_context, :other], default: "personal"  # enum('personal','follow_member','follow_context','other')
    field :title, :string, default: ""  # varchar(64)
    field :value, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_notifications_setting no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group: String.t() | nil,
    handler_id: integer() | nil,
    delivery: :site | :email | :push | nil,
    type: :personal | :follow_member | :follow_context | :other | nil,
    title: String.t() | nil,
    value: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_notifications_setting.

  ## Parâmetros 
    - `bx_notifications_setting`: Struct do bx_notifications_setting (pode ser %BxNotificationsSetting{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_notifications_setting \ %__MODULE__{}, attrs) do
    bx_notifications_setting
    |> cast(attrs, [:group, :handler_id, :delivery, :type, :title, :value, :active, :order])
    |> validate_required([:group, :title])
  end

  @doc """
  Changeset para atualização de um bx_notifications_setting existente.

  ## Parâmetros 
    - `bx_notifications_setting`: Struct do bx_notifications_setting (%BxNotificationsSetting{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_notifications_setting \ %__MODULE__{}, attrs) do
    bx_notifications_setting
    |> cast(attrs, [:group, :handler_id, :delivery, :type, :title, :value, :active, :order])
  end
end
