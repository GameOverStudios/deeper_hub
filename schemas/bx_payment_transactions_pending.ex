defmodule DeeperHub.Schema.BxPaymentTransactionsPending do
  @moduledoc """
  Schema para representação de bx_payment_transactions_pendings no sistema

  Este schema armazena as informações de um bx_payment_transactions_pending.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_transactions_pending" do
    field :client_id, :integer, default: 0  # int(11)
    field :seller_id, :integer, default: 0  # int(11)
    field :type, :string, default: "single"  # varchar(16)
    field :provider, :string, default: ""  # varchar(32)
    field :items, :string, default: "''"  # text
    field :customs, :string, default: "''"  # text
    field :amount, :float, default: 0  # float
    field :currency, :string, default: ""  # varchar(4)
    field :order, :string, default: ""  # varchar(32)
    field :data, :string  # text
    field :error_code, :string, default: ""  # varchar(16)
    field :error_msg, :string, default: ""  # varchar(255)
    field :date, :integer, default: 0  # int(11)
    field :authorized, :integer, default: 0  # tinyint(4)
    field :processed, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_transactions_pending no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    client_id: integer() | nil,
    seller_id: integer() | nil,
    type: String.t() | nil,
    provider: String.t() | nil,
    items: String.t() | nil,
    customs: String.t() | nil,
    amount: float() | nil,
    currency: String.t() | nil,
    order: String.t() | nil,
    data: String.t() | nil,
    error_code: String.t() | nil,
    error_msg: String.t() | nil,
    date: integer() | nil,
    authorized: integer() | nil,
    processed: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_transactions_pending.

  ## Parâmetros 
    - `bx_payment_transactions_pending`: Struct do bx_payment_transactions_pending (pode ser %BxPaymentTransactionsPending{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_transactions_pending \ %__MODULE__{}, attrs) do
    bx_payment_transactions_pending
    |> cast(attrs, [:client_id, :seller_id, :type, :provider, :items, :customs, :amount, :currency, :order, :data, :error_code, :error_msg, :date, :authorized, :processed])
    |> validate_required([:provider, :currency, :order, :data, :error_code, :error_msg])
  end

  @doc """
  Changeset para atualização de um bx_payment_transactions_pending existente.

  ## Parâmetros 
    - `bx_payment_transactions_pending`: Struct do bx_payment_transactions_pending (%BxPaymentTransactionsPending{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_transactions_pending \ %__MODULE__{}, attrs) do
    bx_payment_transactions_pending
    |> cast(attrs, [:client_id, :seller_id, :type, :provider, :items, :customs, :amount, :currency, :order, :data, :error_code, :error_msg, :date, :authorized, :processed])
  end
end
