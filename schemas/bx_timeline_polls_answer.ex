defmodule DeeperHub.Schema.BxTimelinePollsAnswer do
  @moduledoc """
  Schema para representação de bx_timeline_polls_answers no sistema

  Este schema armazena as informações de um bx_timeline_polls_answer.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_polls_answers" do
    field :poll_id, :integer, default: 0  # int(11) unsigned
    field :title, :string  # varchar(255)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_polls_answer no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    poll_id: integer() | nil,
    title: String.t() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_polls_answer.

  ## Parâmetros 
    - `bx_timeline_polls_answer`: Struct do bx_timeline_polls_answer (pode ser %BxTimelinePollsAnswer{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_polls_answer \ %__MODULE__{}, attrs) do
    bx_timeline_polls_answer
    |> cast(attrs, [:poll_id, :title, :rate, :votes, :order])
    |> validate_required([:title])
  end

  @doc """
  Changeset para atualização de um bx_timeline_polls_answer existente.

  ## Parâmetros 
    - `bx_timeline_polls_answer`: Struct do bx_timeline_polls_answer (%BxTimelinePollsAnswer{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_polls_answer \ %__MODULE__{}, attrs) do
    bx_timeline_polls_answer
    |> cast(attrs, [:poll_id, :title, :rate, :votes, :order])
  end
end
