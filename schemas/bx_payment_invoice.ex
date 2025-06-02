defmodule DeeperHub.Schema.BxPaymentInvoice do
  @moduledoc """
  Schema para representação de bx_payment_invoices no sistema

  Este schema armazena as informações de um bx_payment_invoice.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_invoices" do
    field :name, :string, default: ""  # varchar(64)
    field :commissionaire_id, :string, default: ""  # varchar(32)
    field :committent_id, :string, default: ""  # varchar(32)
    field :amount, :float, default: 0  # float
    field :currency, :string, default: ""  # varchar(4)
    field :period_start, :integer, default: 0  # int(11)
    field :period_end, :integer, default: 0  # int(11)
    field :date_issue, :integer, default: 0  # int(11)
    field :date_due, :integer, default: 0  # int(11)
    field :status, :string, default: "unpaid"  # varchar(32)
    field :ntf_exp, :integer, default: 0  # tinyint(4)
    field :ntf_due, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_invoice no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    commissionaire_id: String.t() | nil,
    committent_id: String.t() | nil,
    amount: float() | nil,
    currency: String.t() | nil,
    period_start: integer() | nil,
    period_end: integer() | nil,
    date_issue: integer() | nil,
    date_due: integer() | nil,
    status: String.t() | nil,
    ntf_exp: integer() | nil,
    ntf_due: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_invoice.

  ## Parâmetros 
    - `bx_payment_invoice`: Struct do bx_payment_invoice (pode ser %BxPaymentInvoice{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_invoice \ %__MODULE__{}, attrs) do
    bx_payment_invoice
    |> cast(attrs, [:name, :commissionaire_id, :committent_id, :amount, :currency, :period_start, :period_end, :date_issue, :date_due, :status, :ntf_exp, :ntf_due])
    |> validate_required([:name, :commissionaire_id, :committent_id, :currency])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_payment_invoice existente.

  ## Parâmetros 
    - `bx_payment_invoice`: Struct do bx_payment_invoice (%BxPaymentInvoice{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_invoice \ %__MODULE__{}, attrs) do
    bx_payment_invoice
    |> cast(attrs, [:name, :commissionaire_id, :committent_id, :amount, :currency, :period_start, :period_end, :date_issue, :date_due, :status, :ntf_exp, :ntf_due])
    |> unique_constraint(:name)
  end
end
