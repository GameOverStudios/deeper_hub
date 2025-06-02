defmodule DeeperHub.Schema.BxReputationProfilesLevel do
  @moduledoc """
  Schema para representação de bx_reputation_profiles_levels no sistema

  Este schema armazena as informações de um bx_reputation_profiles_level.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reputation_profiles_levels" do
    field :profile_id, :integer, default: 0  # int(11)
    field :level_id, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reputation_profiles_level no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    level_id: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reputation_profiles_level.

  ## Parâmetros 
    - `bx_reputation_profiles_level`: Struct do bx_reputation_profiles_level (pode ser %BxReputationProfilesLevel{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reputation_profiles_level \ %__MODULE__{}, attrs) do
    bx_reputation_profiles_level
    |> cast(attrs, [:profile_id, :level_id, :date])
  end

  @doc """
  Changeset para atualização de um bx_reputation_profiles_level existente.

  ## Parâmetros 
    - `bx_reputation_profiles_level`: Struct do bx_reputation_profiles_level (%BxReputationProfilesLevel{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reputation_profiles_level \ %__MODULE__{}, attrs) do
    bx_reputation_profiles_level
    |> cast(attrs, [:profile_id, :level_id, :date])
  end
end
