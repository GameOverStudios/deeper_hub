defmodule DeeperHub.Schema.BxForumPollsAnswersVote do
  @moduledoc """
  Schema para representação de bx_forum_polls_answers_votes no sistema

  Este schema armazena as informações de um bx_forum_polls_answers_vote.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_forum_polls_answers_votes" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_forum_polls_answers_vote no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count: integer() | nil,
    sum: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_forum_polls_answers_vote.

  ## Parâmetros 
    - `bx_forum_polls_answers_vote`: Struct do bx_forum_polls_answers_vote (pode ser %BxForumPollsAnswersVote{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_forum_polls_answers_vote \ %__MODULE__{}, attrs) do
    bx_forum_polls_answers_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_forum_polls_answers_vote existente.

  ## Parâmetros 
    - `bx_forum_polls_answers_vote`: Struct do bx_forum_polls_answers_vote (%BxForumPollsAnswersVote{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_forum_polls_answers_vote \ %__MODULE__{}, attrs) do
    bx_forum_polls_answers_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end
end
