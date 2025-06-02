defmodule DeeperHub.Schema.BxMarketScore do
  @moduledoc """
  Schema para representação de bx_market_scores no sistema

  Este schema armazena as informações de um bx_market_score.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_market_scores" do
    field :object_id, :integer, default: 0  # int(11)
    field :count_up, :integer, default: 0  # int(11)
    field :count_down, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_market_score no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count_up: integer() | nil,
    count_down: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_market_score.

  ## Parâmetros 
    - `bx_market_score`: Struct do bx_market_score (pode ser %BxMarketScore{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_market_score \ %__MODULE__{}, attrs) do
    bx_market_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_market_score existente.

  ## Parâmetros 
    - `bx_market_score`: Struct do bx_market_score (%BxMarketScore{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_market_score \ %__MODULE__{}, attrs) do
    bx_market_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end
end
