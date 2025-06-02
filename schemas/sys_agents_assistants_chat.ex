defmodule DeeperHub.Schema.SysAgentsAssistantsChat do
  @moduledoc """
  Schema para representação de sys_agents_assistants_chats no sistema

  Este schema armazena as informações de um sys_agents_assistants_chat.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_assistants_chats" do
    field :name, :string, default: ""  # varchar(128)
    field :type, :integer, default: 1  # tinyint(4)
    field :assistant_id, :integer, default: 0  # int(11)
    field :description, :string  # text
    field :message_id, :integer, default: 0  # int(11)
    field :messages, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :ai_thread_id, :string, default: ""  # varchar(64)
    field :ai_file_id, :string, default: ""  # varchar(64)
    field :stored, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_assistants_chat no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    type: integer() | nil,
    assistant_id: integer() | nil,
    description: String.t() | nil,
    message_id: integer() | nil,
    messages: integer() | nil,
    added: integer() | nil,
    ai_thread_id: String.t() | nil,
    ai_file_id: String.t() | nil,
    stored: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_assistants_chat.

  ## Parâmetros 
    - `sys_agents_assistants_chat`: Struct do sys_agents_assistants_chat (pode ser %SysAgentsAssistantsChat{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_assistants_chat \ %__MODULE__{}, attrs) do
    sys_agents_assistants_chat
    |> cast(attrs, [:name, :type, :assistant_id, :description, :message_id, :messages, :added, :ai_thread_id, :ai_file_id, :stored])
    |> validate_required([:name, :description, :ai_thread_id, :ai_file_id])
  end

  @doc """
  Changeset para atualização de um sys_agents_assistants_chat existente.

  ## Parâmetros 
    - `sys_agents_assistants_chat`: Struct do sys_agents_assistants_chat (%SysAgentsAssistantsChat{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_assistants_chat \ %__MODULE__{}, attrs) do
    sys_agents_assistants_chat
    |> cast(attrs, [:name, :type, :assistant_id, :description, :message_id, :messages, :added, :ai_thread_id, :ai_file_id, :stored])
  end
end
