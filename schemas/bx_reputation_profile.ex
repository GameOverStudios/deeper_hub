defmodule DeeperHub.Schema.BxReputationProfile do
  @moduledoc """
  Schema para representação de bx_reputation_profiles no sistema

  Este schema armazena as informações de um bx_reputation_profile.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reputation_profiles" do
    field :points, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reputation_profile no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    points: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reputation_profile.

  ## Parâmetros 
    - `bx_reputation_profile`: Struct do bx_reputation_profile (pode ser %BxReputationProfile{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reputation_profile \ %__MODULE__{}, attrs) do
    bx_reputation_profile
    |> cast(attrs, [:points])
  end

  @doc """
  Changeset para atualização de um bx_reputation_profile existente.

  ## Parâmetros 
    - `bx_reputation_profile`: Struct do bx_reputation_profile (%BxReputationProfile{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reputation_profile \ %__MODULE__{}, attrs) do
    bx_reputation_profile
    |> cast(attrs, [:points])
  end
end
