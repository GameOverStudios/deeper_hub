defmodule DeeperHub.Schema.BxOrganizationsVote do
  @moduledoc """
  Schema para representação de bx_organizations_votes no sistema

  Este schema armazena as informações de um bx_organizations_vote.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_organizations_votes" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_organizations_vote no sistema
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
  Changeset para criação de um novo bx_organizations_vote.

  ## Parâmetros 
    - `bx_organizations_vote`: Struct do bx_organizations_vote (pode ser %BxOrganizationsVote{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_organizations_vote \ %__MODULE__{}, attrs) do
    bx_organizations_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_organizations_vote existente.

  ## Parâmetros 
    - `bx_organizations_vote`: Struct do bx_organizations_vote (%BxOrganizationsVote{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_organizations_vote \ %__MODULE__{}, attrs) do
    bx_organizations_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end
end
