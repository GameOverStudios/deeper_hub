defmodule DeeperHub.Schema.SysAgentsAutomator do
  @moduledoc """
  Schema para representação de sys_agents_automators no sistema

  Este schema armazena as informações de um sys_agents_automator.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_automators" do
    field :name, :string, default: ""  # varchar(128)
    field :model_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :type, Ecto.Enum, values: [:event, :scheduler, :webhook], default: "event"  # enum('event','scheduler','webhook')
    field :params, :string  # text
    field :alert_unit, :string, default: ""  # varchar(128)
    field :alert_action, :string, default: ""  # varchar(128)
    field :message_id, :integer, default: 0  # int(11)
    field :code, :string  # text
    field :added, :integer, default: 0  # int(11) unsigned
    field :messages, :integer, default: 0  # int(11)
    field :status, Ecto.Enum, values: [:auto, :manual, :ready], default: "auto"  # enum('auto','manual','ready')
    field :active, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_automator no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    model_id: integer() | nil,
    profile_id: integer() | nil,
    type: :event | :scheduler | :webhook | nil,
    params: String.t() | nil,
    alert_unit: String.t() | nil,
    alert_action: String.t() | nil,
    message_id: integer() | nil,
    code: String.t() | nil,
    added: integer() | nil,
    messages: integer() | nil,
    status: :auto | :manual | :ready | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_automator.

  ## Parâmetros 
    - `sys_agents_automator`: Struct do sys_agents_automator (pode ser %SysAgentsAutomator{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_automator \ %__MODULE__{}, attrs) do
    sys_agents_automator
    |> cast(attrs, [:name, :model_id, :profile_id, :type, :params, :alert_unit, :alert_action, :message_id, :code, :added, :messages, :status, :active])
    |> validate_required([:name, :params, :alert_unit, :alert_action, :code])
  end

  @doc """
  Changeset para atualização de um sys_agents_automator existente.

  ## Parâmetros 
    - `sys_agents_automator`: Struct do sys_agents_automator (%SysAgentsAutomator{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_automator \ %__MODULE__{}, attrs) do
    sys_agents_automator
    |> cast(attrs, [:name, :model_id, :profile_id, :type, :params, :alert_unit, :alert_action, :message_id, :code, :added, :messages, :status, :active])
  end
end
