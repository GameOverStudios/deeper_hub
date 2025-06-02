defmodule DeeperHub.Schema.BxSpacesScore do
  @moduledoc """
  Schema para representação de bx_spaces_scores no sistema

  Este schema armazena as informações de um bx_spaces_score.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_spaces_scores" do
    field :object_id, :integer, default: 0  # int(11)
    field :count_up, :integer, default: 0  # int(11)
    field :count_down, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_spaces_score no sistema
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
  Changeset para criação de um novo bx_spaces_score.

  ## Parâmetros 
    - `bx_spaces_score`: Struct do bx_spaces_score (pode ser %BxSpacesScore{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_spaces_score \ %__MODULE__{}, attrs) do
    bx_spaces_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_spaces_score existente.

  ## Parâmetros 
    - `bx_spaces_score`: Struct do bx_spaces_score (%BxSpacesScore{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_spaces_score \ %__MODULE__{}, attrs) do
    bx_spaces_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end
end
