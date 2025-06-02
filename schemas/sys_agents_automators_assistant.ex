defmodule DeeperHub.Schema.SysAgentsAutomatorsAssistant do
  @moduledoc """
  Schema para representação de sys_agents_automators_assistants no sistema

  Este schema armazena as informações de um sys_agents_automators_assistant.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_automators_assistants" do
    field :automator_id, :integer, default: 0  # int(11)
    field :assistant_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_automators_assistant no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    automator_id: integer() | nil,
    assistant_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_automators_assistant.

  ## Parâmetros 
    - `sys_agents_automators_assistant`: Struct do sys_agents_automators_assistant (pode ser %SysAgentsAutomatorsAssistant{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_automators_assistant \ %__MODULE__{}, attrs) do
    sys_agents_automators_assistant
    |> cast(attrs, [:automator_id, :assistant_id])
  end

  @doc """
  Changeset para atualização de um sys_agents_automators_assistant existente.

  ## Parâmetros 
    - `sys_agents_automators_assistant`: Struct do sys_agents_automators_assistant (%SysAgentsAutomatorsAssistant{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_automators_assistant \ %__MODULE__{}, attrs) do
    sys_agents_automators_assistant
    |> cast(attrs, [:automator_id, :assistant_id])
  end
end
