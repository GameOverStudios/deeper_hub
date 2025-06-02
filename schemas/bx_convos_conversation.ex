defmodule DeeperHub.Schema.BxConvosConversation do
  @moduledoc """
  Schema para representação de bx_convos_conversations no sistema

  Este schema armazena as informações de um bx_convos_conversation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_convos_conversations" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :text, :string  # text
    field :allow_edit, :integer, default: 0  # tinyint(4)
    field :views, :integer, default: 0  # int(11)
    field :comments, :integer, default: 0  # int(11)
    field :last_reply_timestamp, :integer  # int(11)
    field :last_reply_profile_id, :integer  # int(10) unsigned
    field :last_reply_comment_id, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_convos_conversation no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    text: String.t() | nil,
    allow_edit: integer() | nil,
    views: integer() | nil,
    comments: integer() | nil,
    last_reply_timestamp: integer() | nil,
    last_reply_profile_id: integer() | nil,
    last_reply_comment_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_convos_conversation.

  ## Parâmetros 
    - `bx_convos_conversation`: Struct do bx_convos_conversation (pode ser %BxConvosConversation{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_convos_conversation \ %__MODULE__{}, attrs) do
    bx_convos_conversation
    |> cast(attrs, [:author, :added, :changed, :text, :allow_edit, :views, :comments, :last_reply_timestamp, :last_reply_profile_id, :last_reply_comment_id])
    |> validate_required([:author, :added, :changed, :text, :last_reply_timestamp, :last_reply_profile_id, :last_reply_comment_id])
  end

  @doc """
  Changeset para atualização de um bx_convos_conversation existente.

  ## Parâmetros 
    - `bx_convos_conversation`: Struct do bx_convos_conversation (%BxConvosConversation{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_convos_conversation \ %__MODULE__{}, attrs) do
    bx_convos_conversation
    |> cast(attrs, [:author, :added, :changed, :text, :allow_edit, :views, :comments, :last_reply_timestamp, :last_reply_profile_id, :last_reply_comment_id])
  end
end
