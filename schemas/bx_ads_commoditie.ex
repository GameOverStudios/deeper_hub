defmodule DeeperHub.Schema.BxAdsCommoditie do
  @moduledoc """
  Schema para representação de bx_ads_commodities no sistema

  Este schema armazena as informações de um bx_ads_commoditie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_commodities" do
    field :entry_id, :integer, default: 0  # int(11)
    field :type, :string, default: ""  # varchar(16)
    field :amount, :float  # float
    field :added, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_commoditie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    type: String.t() | nil,
    amount: float() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_commoditie.

  ## Parâmetros 
    - `bx_ads_commoditie`: Struct do bx_ads_commoditie (pode ser %BxAdsCommoditie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_commoditie \ %__MODULE__{}, attrs) do
    bx_ads_commoditie
    |> cast(attrs, [:entry_id, :type, :amount, :added])
    |> validate_required([:type, :amount, :added])
  end

  @doc """
  Changeset para atualização de um bx_ads_commoditie existente.

  ## Parâmetros 
    - `bx_ads_commoditie`: Struct do bx_ads_commoditie (%BxAdsCommoditie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_commoditie \ %__MODULE__{}, attrs) do
    bx_ads_commoditie
    |> cast(attrs, [:entry_id, :type, :amount, :added])
  end
end
