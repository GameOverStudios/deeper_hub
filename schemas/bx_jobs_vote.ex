defmodule DeeperHub.Schema.BxJobsVote do
  @moduledoc """
  Schema para representação de bx_jobs_votes no sistema

  Este schema armazena as informações de um bx_jobs_vote.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_jobs_votes" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_jobs_vote no sistema
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
  Changeset para criação de um novo bx_jobs_vote.

  ## Parâmetros 
    - `bx_jobs_vote`: Struct do bx_jobs_vote (pode ser %BxJobsVote{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_jobs_vote \ %__MODULE__{}, attrs) do
    bx_jobs_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_jobs_vote existente.

  ## Parâmetros 
    - `bx_jobs_vote`: Struct do bx_jobs_vote (%BxJobsVote{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_jobs_vote \ %__MODULE__{}, attrs) do
    bx_jobs_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end
end
