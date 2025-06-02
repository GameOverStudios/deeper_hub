defmodule DeeperHub.Schema.BxPollsScore do
  @moduledoc """
  Schema para representação de bx_polls_scores no sistema

  Este schema armazena as informações de um bx_polls_score.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_polls_scores" do
    field :object_id, :integer, default: 0  # int(11)
    field :count_up, :integer, default: 0  # int(11)
    field :count_down, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_polls_score no sistema
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
  Changeset para criação de um novo bx_polls_score.

  ## Parâmetros 
    - `bx_polls_score`: Struct do bx_polls_score (pode ser %BxPollsScore{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_polls_score \ %__MODULE__{}, attrs) do
    bx_polls_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_polls_score existente.

  ## Parâmetros 
    - `bx_polls_score`: Struct do bx_polls_score (%BxPollsScore{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_polls_score \ %__MODULE__{}, attrs) do
    bx_polls_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end
end
