defmodule DeeperHub.Schema.BxJobsQnrAnswer do
  @moduledoc """
  Schema para representação de bx_jobs_qnr_answers no sistema

  Este schema armazena as informações de um bx_jobs_qnr_answer.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_jobs_qnr_answers" do
    field :question_id, :integer, default: 0  # int(10) unsigned
    field :profile_id, :integer, default: 0  # int(10) unsigned
    field :added, :integer, default: 0  # int(10)
    field :answer, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_jobs_qnr_answer no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    question_id: integer() | nil,
    profile_id: integer() | nil,
    added: integer() | nil,
    answer: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_jobs_qnr_answer.

  ## Parâmetros 
    - `bx_jobs_qnr_answer`: Struct do bx_jobs_qnr_answer (pode ser %BxJobsQnrAnswer{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_jobs_qnr_answer \ %__MODULE__{}, attrs) do
    bx_jobs_qnr_answer
    |> cast(attrs, [:question_id, :profile_id, :added, :answer])
    |> validate_required([:answer])
  end

  @doc """
  Changeset para atualização de um bx_jobs_qnr_answer existente.

  ## Parâmetros 
    - `bx_jobs_qnr_answer`: Struct do bx_jobs_qnr_answer (%BxJobsQnrAnswer{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_jobs_qnr_answer \ %__MODULE__{}, attrs) do
    bx_jobs_qnr_answer
    |> cast(attrs, [:question_id, :profile_id, :added, :answer])
  end
end
