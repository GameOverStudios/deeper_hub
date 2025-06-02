defmodule DeeperHub.Schema.BxPaymentCommission do
  @moduledoc """
  Schema para representação de bx_payment_commissions no sistema

  Este schema armazena as informações de um bx_payment_commission.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_commissions" do
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(128)
    field :description, :string, default: ""  # varchar(128)
    field :acl_id, :integer, default: 0  # int(11)
    field :percentage, :float, default: 0  # float
    field :installment, :float, default: 0  # float
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_commission no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    caption: String.t() | nil,
    description: String.t() | nil,
    acl_id: integer() | nil,
    percentage: float() | nil,
    installment: float() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_commission.

  ## Parâmetros 
    - `bx_payment_commission`: Struct do bx_payment_commission (pode ser %BxPaymentCommission{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_commission \ %__MODULE__{}, attrs) do
    bx_payment_commission
    |> cast(attrs, [:name, :caption, :description, :acl_id, :percentage, :installment, :active, :order])
    |> validate_required([:name, :caption, :description])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_payment_commission existente.

  ## Parâmetros 
    - `bx_payment_commission`: Struct do bx_payment_commission (%BxPaymentCommission{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_commission \ %__MODULE__{}, attrs) do
    bx_payment_commission
    |> cast(attrs, [:name, :caption, :description, :acl_id, :percentage, :installment, :active, :order])
    |> unique_constraint(:name)
  end
end
