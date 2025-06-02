defmodule DeeperHub.Schema.BxEventsPrice do
  @moduledoc """
  Schema para representação de bx_events_prices no sistema

  Este schema armazena as informações de um bx_events_price.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_events_prices" do
    field :profile_id, :integer, default: 0  # int(11)
    field :role_id, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(128)
    field :period, :integer, default: 1  # int(11) unsigned
    field :period_unit, :string, default: ""  # varchar(32)
    field :price, :float, default: 1  # float unsigned
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_events_price no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    role_id: integer() | nil,
    name: String.t() | nil,
    period: integer() | nil,
    period_unit: String.t() | nil,
    price: float() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_events_price.

  ## Parâmetros 
    - `bx_events_price`: Struct do bx_events_price (pode ser %BxEventsPrice{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_events_price \ %__MODULE__{}, attrs) do
    bx_events_price
    |> cast(attrs, [:profile_id, :role_id, :name, :period, :period_unit, :price, :order])
    |> validate_required([:name, :period_unit, :order])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_events_price existente.

  ## Parâmetros 
    - `bx_events_price`: Struct do bx_events_price (%BxEventsPrice{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_events_price \ %__MODULE__{}, attrs) do
    bx_events_price
    |> cast(attrs, [:profile_id, :role_id, :name, :period, :period_unit, :price, :order])
    |> unique_constraint(:name)
  end
end
