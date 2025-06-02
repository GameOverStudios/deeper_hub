defmodule DeeperHub.Schema.BxCreditsProfile do
  @moduledoc """
  Schema para representação de bx_credits_profiles no sistema

  Este schema armazena as informações de um bx_credits_profile.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_profiles" do
    field :wdw_clearing, :integer, default: 0  # int(11) unsigned
    field :wdw_minimum, :integer, default: 0  # int(11) unsigned
    field :wdw_remaining, :integer, default: 0  # int(11) unsigned
    field :balance, :float, default: 0  # float

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_profile no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    wdw_clearing: integer() | nil,
    wdw_minimum: integer() | nil,
    wdw_remaining: integer() | nil,
    balance: float() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_profile.

  ## Parâmetros 
    - `bx_credits_profile`: Struct do bx_credits_profile (pode ser %BxCreditsProfile{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_profile \ %__MODULE__{}, attrs) do
    bx_credits_profile
    |> cast(attrs, [:wdw_clearing, :wdw_minimum, :wdw_remaining, :balance])
  end

  @doc """
  Changeset para atualização de um bx_credits_profile existente.

  ## Parâmetros 
    - `bx_credits_profile`: Struct do bx_credits_profile (%BxCreditsProfile{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_profile \ %__MODULE__{}, attrs) do
    bx_credits_profile
    |> cast(attrs, [:wdw_clearing, :wdw_minimum, :wdw_remaining, :balance])
  end
end
