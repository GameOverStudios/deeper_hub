defmodule DeeperHub.Schema.BxPollsSubentrie do
  @moduledoc """
  Schema para representação de bx_polls_subentries no sistema

  Este schema armazena as informações de um bx_polls_subentrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_polls_subentries" do
    field :entry_id, :integer, default: 0  # int(11) unsigned
    field :title, :string  # varchar(255)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_polls_subentrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    title: String.t() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_polls_subentrie.

  ## Parâmetros 
    - `bx_polls_subentrie`: Struct do bx_polls_subentrie (pode ser %BxPollsSubentrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_polls_subentrie \ %__MODULE__{}, attrs) do
    bx_polls_subentrie
    |> cast(attrs, [:entry_id, :title, :rate, :votes, :order])
    |> validate_required([:title])
  end

  @doc """
  Changeset para atualização de um bx_polls_subentrie existente.

  ## Parâmetros 
    - `bx_polls_subentrie`: Struct do bx_polls_subentrie (%BxPollsSubentrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_polls_subentrie \ %__MODULE__{}, attrs) do
    bx_polls_subentrie
    |> cast(attrs, [:entry_id, :title, :rate, :votes, :order])
  end
end
