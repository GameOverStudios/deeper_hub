defmodule DeeperHub.Schema.BxPaymentSubscription do
  @moduledoc """
  Schema para representação de bx_payment_subscriptions no sistema

  Este schema armazena as informações de um bx_payment_subscription.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_subscriptions" do
    field :pending_id, :integer, default: 0  # int(11)
    field :customer_id, :string, default: ""  # varchar(32)
    field :subscription_id, :string, default: ""  # varchar(32)
    field :period, :integer, default: 1  # int(11) unsigned
    field :period_unit, :string, default: ""  # varchar(32)
    field :trial, :integer, default: 0  # int(11) unsigned
    field :date_add, :integer, default: 0  # int(11)
    field :date_next, :integer, default: 0  # int(11)
    field :pay_attempts, :integer, default: 0  # tinyint(4)
    field :status, :string, default: "unpaid"  # varchar(32)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_subscription no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    pending_id: integer() | nil,
    customer_id: String.t() | nil,
    subscription_id: String.t() | nil,
    period: integer() | nil,
    period_unit: String.t() | nil,
    trial: integer() | nil,
    date_add: integer() | nil,
    date_next: integer() | nil,
    pay_attempts: integer() | nil,
    status: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_subscription.

  ## Parâmetros 
    - `bx_payment_subscription`: Struct do bx_payment_subscription (pode ser %BxPaymentSubscription{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_subscription \ %__MODULE__{}, attrs) do
    bx_payment_subscription
    |> cast(attrs, [:pending_id, :customer_id, :subscription_id, :period, :period_unit, :trial, :date_add, :date_next, :pay_attempts, :status])
    |> validate_required([:customer_id, :subscription_id, :period_unit])
    |> unique_constraint(:pending_id)
  end

  @doc """
  Changeset para atualização de um bx_payment_subscription existente.

  ## Parâmetros 
    - `bx_payment_subscription`: Struct do bx_payment_subscription (%BxPaymentSubscription{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_subscription \ %__MODULE__{}, attrs) do
    bx_payment_subscription
    |> cast(attrs, [:pending_id, :customer_id, :subscription_id, :period, :period_unit, :trial, :date_add, :date_next, :pay_attempts, :status])
    |> unique_constraint(:pending_id)
  end
end
