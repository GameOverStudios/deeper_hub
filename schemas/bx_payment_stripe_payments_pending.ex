defmodule DeeperHub.Schema.BxPaymentStripePaymentsPending do
  @moduledoc """
  Schema para representação de bx_payment_stripe_payments_pendings no sistema

  Este schema armazena as informações de um bx_payment_stripe_payments_pending.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_stripe_payments_pending" do
    field :subscription_id, :string, default: ""  # varchar(32)
    field :amount, :float, default: 0  # float
    field :currency, :string, default: ""  # varchar(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_stripe_payments_pending no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    subscription_id: String.t() | nil,
    amount: float() | nil,
    currency: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_stripe_payments_pending.

  ## Parâmetros 
    - `bx_payment_stripe_payments_pending`: Struct do bx_payment_stripe_payments_pending (pode ser %BxPaymentStripePaymentsPending{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_stripe_payments_pending \ %__MODULE__{}, attrs) do
    bx_payment_stripe_payments_pending
    |> cast(attrs, [:subscription_id, :amount, :currency])
    |> validate_required([:subscription_id, :currency])
    |> unique_constraint(:subscription_id)
  end

  @doc """
  Changeset para atualização de um bx_payment_stripe_payments_pending existente.

  ## Parâmetros 
    - `bx_payment_stripe_payments_pending`: Struct do bx_payment_stripe_payments_pending (%BxPaymentStripePaymentsPending{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_stripe_payments_pending \ %__MODULE__{}, attrs) do
    bx_payment_stripe_payments_pending
    |> cast(attrs, [:subscription_id, :amount, :currency])
    |> unique_constraint(:subscription_id)
  end
end
