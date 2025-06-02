defmodule DeeperHub.Schema.BxFdbAnswer do
  @moduledoc """
  Schema para representação de bx_fdb_answers no sistema

  Este schema armazena as informações de um bx_fdb_answer.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_fdb_answers" do
    field :question_id, :integer, default: 0  # int(11) unsigned
    field :title, :string  # varchar(255)
    field :important, :integer, default: 0  # tinyint(4)
    field :data, :string, default: "''"  # text
    field :votes, :integer, default: 0  # int(11)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_fdb_answer no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    question_id: integer() | nil,
    title: String.t() | nil,
    important: integer() | nil,
    data: String.t() | nil,
    votes: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_fdb_answer.

  ## Parâmetros 
    - `bx_fdb_answer`: Struct do bx_fdb_answer (pode ser %BxFdbAnswer{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_fdb_answer \ %__MODULE__{}, attrs) do
    bx_fdb_answer
    |> cast(attrs, [:question_id, :title, :important, :data, :votes, :order])
    |> validate_required([:title])
  end

  @doc """
  Changeset para atualização de um bx_fdb_answer existente.

  ## Parâmetros 
    - `bx_fdb_answer`: Struct do bx_fdb_answer (%BxFdbAnswer{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_fdb_answer \ %__MODULE__{}, attrs) do
    bx_fdb_answer
    |> cast(attrs, [:question_id, :title, :important, :data, :votes, :order])
  end
end
