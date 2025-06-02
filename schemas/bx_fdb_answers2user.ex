defmodule DeeperHub.Schema.BxFdbAnswers2user do
  @moduledoc """
  Schema para representação de bx_fdb_answers2users no sistema

  Este schema armazena as informações de um bx_fdb_answers2user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_fdb_answers2users" do
    field :answer_id, :integer, default: 0  # int(11) unsigned
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :text, :string, default: ""  # varchar(255)
    field :added, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_fdb_answers2user no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    answer_id: integer() | nil,
    profile_id: integer() | nil,
    text: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_fdb_answers2user.

  ## Parâmetros 
    - `bx_fdb_answers2user`: Struct do bx_fdb_answers2user (pode ser %BxFdbAnswers2user{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_fdb_answers2user \ %__MODULE__{}, attrs) do
    bx_fdb_answers2user
    |> cast(attrs, [:answer_id, :profile_id, :text, :added])
    |> validate_required([:text])
  end

  @doc """
  Changeset para atualização de um bx_fdb_answers2user existente.

  ## Parâmetros 
    - `bx_fdb_answers2user`: Struct do bx_fdb_answers2user (%BxFdbAnswers2user{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_fdb_answers2user \ %__MODULE__{}, attrs) do
    bx_fdb_answers2user
    |> cast(attrs, [:answer_id, :profile_id, :text, :added])
  end
end
