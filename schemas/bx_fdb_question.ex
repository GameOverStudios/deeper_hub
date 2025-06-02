defmodule DeeperHub.Schema.BxFdbQuestion do
  @moduledoc """
  Schema para representação de bx_fdb_questions no sistema

  Este schema armazena as informações de um bx_fdb_question.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_fdb_questions" do
    field :author, :integer  # int(11) unsigned
    field :added, :integer, default: 0  # int(11)
    field :changed, :integer, default: 0  # int(11)
    field :text, :string  # text
    field :lifetime, :integer, default: 0  # int(11)
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :status_admin, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_fdb_question no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    text: String.t() | nil,
    lifetime: integer() | nil,
    allow_view_to: String.t() | nil,
    status_admin: :active | :hidden | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_fdb_question.

  ## Parâmetros 
    - `bx_fdb_question`: Struct do bx_fdb_question (pode ser %BxFdbQuestion{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_fdb_question \ %__MODULE__{}, attrs) do
    bx_fdb_question
    |> cast(attrs, [:author, :added, :changed, :text, :lifetime, :allow_view_to, :status_admin])
    |> validate_required([:author, :text])
  end

  @doc """
  Changeset para atualização de um bx_fdb_question existente.

  ## Parâmetros 
    - `bx_fdb_question`: Struct do bx_fdb_question (%BxFdbQuestion{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_fdb_question \ %__MODULE__{}, attrs) do
    bx_fdb_question
    |> cast(attrs, [:author, :added, :changed, :text, :lifetime, :allow_view_to, :status_admin])
  end
end
