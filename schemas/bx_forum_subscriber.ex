defmodule DeeperHub.Schema.BxForumSubscriber do
  @moduledoc """
  Schema para representação de bx_forum_subscribers no sistema

  Este schema armazena as informações de um bx_forum_subscriber.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_forum_subscribers" do
    field :initiator, :integer  # int(11)
    field :content, :integer  # int(11)
    field :added, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_forum_subscriber no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_forum_subscriber.

  ## Parâmetros 
    - `bx_forum_subscriber`: Struct do bx_forum_subscriber (pode ser %BxForumSubscriber{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_forum_subscriber \ %__MODULE__{}, attrs) do
    bx_forum_subscriber
    |> cast(attrs, [:initiator, :content, :added])
    |> validate_required([:initiator, :content, :added])
  end

  @doc """
  Changeset para atualização de um bx_forum_subscriber existente.

  ## Parâmetros 
    - `bx_forum_subscriber`: Struct do bx_forum_subscriber (%BxForumSubscriber{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_forum_subscriber \ %__MODULE__{}, attrs) do
    bx_forum_subscriber
    |> cast(attrs, [:initiator, :content, :added])
  end
end
