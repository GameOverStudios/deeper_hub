defmodule DeeperHub.Schema.BxEventsQnrQuestion do
  @moduledoc """
  Schema para representação de bx_events_qnr_questions no sistema

  Este schema armazena as informações de um bx_events_qnr_question.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_events_qnr_questions" do
    field :content_id, :integer, default: 0  # int(10) unsigned
    field :added, :integer, default: 0  # int(10)
    field :action, :string, default: "add"  # varchar(16)
    field :question, :string, default: ""  # varchar(255)
    field :answer, :string, default: "text"  # varchar(16)
    field :extra, :string  # text
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_events_qnr_question no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    added: integer() | nil,
    action: String.t() | nil,
    question: String.t() | nil,
    answer: String.t() | nil,
    extra: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_events_qnr_question.

  ## Parâmetros 
    - `bx_events_qnr_question`: Struct do bx_events_qnr_question (pode ser %BxEventsQnrQuestion{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_events_qnr_question \ %__MODULE__{}, attrs) do
    bx_events_qnr_question
    |> cast(attrs, [:content_id, :added, :action, :question, :answer, :extra, :order])
    |> validate_required([:question, :extra])
  end

  @doc """
  Changeset para atualização de um bx_events_qnr_question existente.

  ## Parâmetros 
    - `bx_events_qnr_question`: Struct do bx_events_qnr_question (%BxEventsQnrQuestion{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_events_qnr_question \ %__MODULE__{}, attrs) do
    bx_events_qnr_question
    |> cast(attrs, [:content_id, :added, :action, :question, :answer, :extra, :order])
  end
end
