defmodule DeeperHub.Schema.BxPaymentTransaction do
  @moduledoc """
  Schema para representação de bx_payment_transactions no sistema

  Este schema armazena as informações de um bx_payment_transaction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_transactions" do
    field :pending_id, :integer, default: 0  # int(11)
    field :client_id, :integer, default: 0  # int(11)
    field :seller_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :module_id, :integer, default: 0  # int(11)
    field :item_id, :integer, default: 0  # int(11)
    field :item_count, :integer, default: 0  # int(11)
    field :amount, :float, default: 0  # float
    field :currency, :string, default: ""  # varchar(4)
    field :license, :string, default: ""  # varchar(16)
    field :date, :integer, default: 0  # int(11)
    field :new, :boolean, default: true  # tinyint(1)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_transaction no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    pending_id: integer() | nil,
    client_id: integer() | nil,
    seller_id: integer() | nil,
    author_id: integer() | nil,
    module_id: integer() | nil,
    item_id: integer() | nil,
    item_count: integer() | nil,
    amount: float() | nil,
    currency: String.t() | nil,
    license: String.t() | nil,
    date: integer() | nil,
    new: boolean() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_transaction.

  ## Parâmetros 
    - `bx_payment_transaction`: Struct do bx_payment_transaction (pode ser %BxPaymentTransaction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_transaction \ %__MODULE__{}, attrs) do
    bx_payment_transaction
    |> cast(attrs, [:pending_id, :client_id, :seller_id, :author_id, :module_id, :item_id, :item_count, :amount, :currency, :license, :date, :new])
    |> validate_required([:currency, :license])
  end

  @doc """
  Changeset para atualização de um bx_payment_transaction existente.

  ## Parâmetros 
    - `bx_payment_transaction`: Struct do bx_payment_transaction (%BxPaymentTransaction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_transaction \ %__MODULE__{}, attrs) do
    bx_payment_transaction
    |> cast(attrs, [:pending_id, :client_id, :seller_id, :author_id, :module_id, :item_id, :item_count, :amount, :currency, :license, :date, :new])
  end
end
