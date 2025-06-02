defmodule DeeperHub.Schema.BxReviewsVotingOption do
  @moduledoc """
  Schema para representação de bx_reviews_voting_options no sistema

  Este schema armazena as informações de um bx_reviews_voting_option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reviews_voting_options" do
    field :lkey, :string, default: ""  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reviews_voting_option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    lkey: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reviews_voting_option.

  ## Parâmetros 
    - `bx_reviews_voting_option`: Struct do bx_reviews_voting_option (pode ser %BxReviewsVotingOption{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reviews_voting_option \ %__MODULE__{}, attrs) do
    bx_reviews_voting_option
    |> cast(attrs, [:lkey, :order])
    |> validate_required([:lkey, :order])
  end

  @doc """
  Changeset para atualização de um bx_reviews_voting_option existente.

  ## Parâmetros 
    - `bx_reviews_voting_option`: Struct do bx_reviews_voting_option (%BxReviewsVotingOption{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reviews_voting_option \ %__MODULE__{}, attrs) do
    bx_reviews_voting_option
    |> cast(attrs, [:lkey, :order])
  end
end
