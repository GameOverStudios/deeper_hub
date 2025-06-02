defmodule DeeperHub.Schema.SysAgentsAutomatorsMessage do
  @moduledoc """
  Schema para representação de sys_agents_automators_messages no sistema

  Este schema armazena as informações de um sys_agents_automators_message.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_automators_messages" do
    field :cmt_id, :integer  # int(11)
    field :cmt_parent_id, :integer, default: 0  # int(11)
    field :cmt_vparent_id, :integer, default: 0  # int(11)
    field :cmt_object_id, :integer, default: 0  # int(11)
    field :cmt_author_id, :integer, default: 0  # int(11)
    field :cmt_level, :integer, default: 0  # int(11)
    field :cmt_text, :string  # text
    field :cmt_mood, :integer, default: 0  # tinyint(4)
    field :cmt_rate, :integer, default: 0  # int(11)
    field :cmt_rate_count, :integer, default: 0  # int(11)
    field :cmt_time, :integer, default: 0  # int(11) unsigned
    field :cmt_replies, :integer, default: 0  # int(11)
    field :cmt_pinned, :integer, default: 0  # int(11)
    field :cmt_cf, :integer, default: 1  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_automators_message no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    cmt_id: integer() | nil,
    cmt_parent_id: integer() | nil,
    cmt_vparent_id: integer() | nil,
    cmt_object_id: integer() | nil,
    cmt_author_id: integer() | nil,
    cmt_level: integer() | nil,
    cmt_text: String.t() | nil,
    cmt_mood: integer() | nil,
    cmt_rate: integer() | nil,
    cmt_rate_count: integer() | nil,
    cmt_time: integer() | nil,
    cmt_replies: integer() | nil,
    cmt_pinned: integer() | nil,
    cmt_cf: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_automators_message.

  ## Parâmetros 
    - `sys_agents_automators_message`: Struct do sys_agents_automators_message (pode ser %SysAgentsAutomatorsMessage{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_automators_message \ %__MODULE__{}, attrs) do
    sys_agents_automators_message
    |> cast(attrs, [:cmt_id, :cmt_parent_id, :cmt_vparent_id, :cmt_object_id, :cmt_author_id, :cmt_level, :cmt_text, :cmt_mood, :cmt_rate, :cmt_rate_count, :cmt_time, :cmt_replies, :cmt_pinned, :cmt_cf])
    |> validate_required([:cmt_id, :cmt_text])
  end

  @doc """
  Changeset para atualização de um sys_agents_automators_message existente.

  ## Parâmetros 
    - `sys_agents_automators_message`: Struct do sys_agents_automators_message (%SysAgentsAutomatorsMessage{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_automators_message \ %__MODULE__{}, attrs) do
    sys_agents_automators_message
    |> cast(attrs, [:cmt_id, :cmt_parent_id, :cmt_vparent_id, :cmt_object_id, :cmt_author_id, :cmt_level, :cmt_text, :cmt_mood, :cmt_rate, :cmt_rate_count, :cmt_time, :cmt_replies, :cmt_pinned, :cmt_cf])
  end
end
