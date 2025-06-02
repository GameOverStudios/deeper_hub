defmodule DeeperHub.Schema.BxDonationsType do
  @moduledoc """
  Schema para representação de bx_donations_types no sistema

  Este schema armazena as informações de um bx_donations_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_donations_types" do
    field :name, :string, default: ""  # varchar(128)
    field :title, :string, default: ""  # varchar(128)
    field :period, :integer, default: 0  # int(11) unsigned
    field :period_unit, :string, default: ""  # varchar(32)
    field :amount, :float, default: 0  # float unsigned
    field :custom, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_donations_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    period: integer() | nil,
    period_unit: String.t() | nil,
    amount: float() | nil,
    custom: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_donations_type.

  ## Parâmetros 
    - `bx_donations_type`: Struct do bx_donations_type (pode ser %BxDonationsType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_donations_type \ %__MODULE__{}, attrs) do
    bx_donations_type
    |> cast(attrs, [:name, :title, :period, :period_unit, :amount, :custom, :active, :order])
    |> validate_required([:name, :title, :period_unit, :order])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_donations_type existente.

  ## Parâmetros 
    - `bx_donations_type`: Struct do bx_donations_type (%BxDonationsType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_donations_type \ %__MODULE__{}, attrs) do
    bx_donations_type
    |> cast(attrs, [:name, :title, :period, :period_unit, :amount, :custom, :active, :order])
    |> unique_constraint(:name)
  end
end
