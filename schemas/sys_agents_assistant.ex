defmodule DeeperHub.Schema.SysAgentsAssistant do
  @moduledoc """
  Schema para representação de sys_agents_assistants no sistema

  Este schema armazena as informações de um sys_agents_assistant.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_assistants" do
    field :name, :string, default: ""  # varchar(128)
    field :model_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :description, :string  # text
    field :prompt, :string  # text
    field :ai_vs_id, :string, default: ""  # varchar(64)
    field :ai_asst_id, :string, default: ""  # varchar(64)
    field :added, :integer, default: 0  # int(11)
    field :active, :integer, default: 0  # tinyint(4)
    field :hidden, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_assistant no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    model_id: integer() | nil,
    profile_id: integer() | nil,
    description: String.t() | nil,
    prompt: String.t() | nil,
    ai_vs_id: String.t() | nil,
    ai_asst_id: String.t() | nil,
    added: integer() | nil,
    active: integer() | nil,
    hidden: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_assistant.

  ## Parâmetros 
    - `sys_agents_assistant`: Struct do sys_agents_assistant (pode ser %SysAgentsAssistant{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_assistant \ %__MODULE__{}, attrs) do
    sys_agents_assistant
    |> cast(attrs, [:name, :model_id, :profile_id, :description, :prompt, :ai_vs_id, :ai_asst_id, :added, :active, :hidden])
    |> validate_required([:name, :description, :prompt, :ai_vs_id, :ai_asst_id])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_agents_assistant existente.

  ## Parâmetros 
    - `sys_agents_assistant`: Struct do sys_agents_assistant (%SysAgentsAssistant{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_assistant \ %__MODULE__{}, attrs) do
    sys_agents_assistant
    |> cast(attrs, [:name, :model_id, :profile_id, :description, :prompt, :ai_vs_id, :ai_asst_id, :added, :active, :hidden])
    |> unique_constraint(:name)
  end
end
