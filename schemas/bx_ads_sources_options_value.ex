defmodule DeeperHub.Schema.BxAdsSourcesOptionsValue do
  @moduledoc """
  Schema para representação de bx_ads_sources_options_values no sistema

  Este schema armazena as informações de um bx_ads_sources_options_value.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_sources_options_values" do
    field :profile_id, :integer, default: 0  # int(11)
    field :option_id, :integer, default: 0  # int(11)
    field :value, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_sources_options_value no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    option_id: integer() | nil,
    value: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_sources_options_value.

  ## Parâmetros 
    - `bx_ads_sources_options_value`: Struct do bx_ads_sources_options_value (pode ser %BxAdsSourcesOptionsValue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_sources_options_value \ %__MODULE__{}, attrs) do
    bx_ads_sources_options_value
    |> cast(attrs, [:profile_id, :option_id, :value])
    |> validate_required([:value])
  end

  @doc """
  Changeset para atualização de um bx_ads_sources_options_value existente.

  ## Parâmetros 
    - `bx_ads_sources_options_value`: Struct do bx_ads_sources_options_value (%BxAdsSourcesOptionsValue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_sources_options_value \ %__MODULE__{}, attrs) do
    bx_ads_sources_options_value
    |> cast(attrs, [:profile_id, :option_id, :value])
  end
end
