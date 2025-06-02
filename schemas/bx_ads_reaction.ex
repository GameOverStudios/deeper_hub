defmodule DeeperHub.Schema.BxAdsReaction do
  @moduledoc """
  Schema para representação de bx_ads_reactions no sistema

  Este schema armazena as informações de um bx_ads_reaction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_reactions" do
    field :object_id, :integer, default: 0  # int(11)
    field :reaction, :string, default: ""  # varchar(32)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_reaction no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    reaction: String.t() | nil,
    count: integer() | nil,
    sum: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_reaction.

  ## Parâmetros 
    - `bx_ads_reaction`: Struct do bx_ads_reaction (pode ser %BxAdsReaction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_reaction \ %__MODULE__{}, attrs) do
    bx_ads_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
    |> validate_required([:reaction])
  end

  @doc """
  Changeset para atualização de um bx_ads_reaction existente.

  ## Parâmetros 
    - `bx_ads_reaction`: Struct do bx_ads_reaction (%BxAdsReaction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_reaction \ %__MODULE__{}, attrs) do
    bx_ads_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
  end
end
