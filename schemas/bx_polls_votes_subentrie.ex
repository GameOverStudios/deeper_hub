defmodule DeeperHub.Schema.BxPollsVotesSubentrie do
  @moduledoc """
  Schema para representação de bx_polls_votes_subentries no sistema

  Este schema armazena as informações de um bx_polls_votes_subentrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_polls_votes_subentries" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_polls_votes_subentrie no sistema
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
  Changeset para criação de um novo bx_polls_votes_subentrie.

  ## Parâmetros 
    - `bx_polls_votes_subentrie`: Struct do bx_polls_votes_subentrie (pode ser %BxPollsVotesSubentrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_polls_votes_subentrie \ %__MODULE__{}, attrs) do
    bx_polls_votes_subentrie
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_polls_votes_subentrie existente.

  ## Parâmetros 
    - `bx_polls_votes_subentrie`: Struct do bx_polls_votes_subentrie (%BxPollsVotesSubentrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_polls_votes_subentrie \ %__MODULE__{}, attrs) do
    bx_polls_votes_subentrie
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end
end
