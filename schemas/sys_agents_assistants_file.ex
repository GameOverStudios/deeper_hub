defmodule DeeperHub.Schema.SysAgentsAssistantsFile do
  @moduledoc """
  Schema para representação de sys_agents_assistants_files no sistema

  Este schema armazena as informações de um sys_agents_assistants_file.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_assistants_files" do
    field :name, :string, default: ""  # varchar(128)
    field :assistant_id, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :ai_file_id, :string, default: ""  # varchar(64)
    field :ai_file_size, :integer, default: 0  # int(11)
    field :ai_file_status, :string, default: "in_progress"  # varchar(64)
    field :locked, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_assistants_file no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    assistant_id: integer() | nil,
    added: integer() | nil,
    ai_file_id: String.t() | nil,
    ai_file_size: integer() | nil,
    ai_file_status: String.t() | nil,
    locked: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_assistants_file.

  ## Parâmetros 
    - `sys_agents_assistants_file`: Struct do sys_agents_assistants_file (pode ser %SysAgentsAssistantsFile{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_assistants_file \ %__MODULE__{}, attrs) do
    sys_agents_assistants_file
    |> cast(attrs, [:name, :assistant_id, :added, :ai_file_id, :ai_file_size, :ai_file_status, :locked])
    |> validate_required([:name, :ai_file_id])
  end

  @doc """
  Changeset para atualização de um sys_agents_assistants_file existente.

  ## Parâmetros 
    - `sys_agents_assistants_file`: Struct do sys_agents_assistants_file (%SysAgentsAssistantsFile{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_assistants_file \ %__MODULE__{}, attrs) do
    sys_agents_assistants_file
    |> cast(attrs, [:name, :assistant_id, :added, :ai_file_id, :ai_file_size, :ai_file_status, :locked])
  end
end
