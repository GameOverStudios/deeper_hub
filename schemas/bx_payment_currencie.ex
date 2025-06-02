defmodule DeeperHub.Schema.BxPaymentCurrencie do
  @moduledoc """
  Schema para representação de bx_payment_currencies no sistema

  Este schema armazena as informações de um bx_payment_currencie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_currencies" do
    field :code, :string, default: ""  # varchar(4)
    field :rate, :float, default: 0  # float

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_currencie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    code: String.t() | nil,
    rate: float() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_currencie.

  ## Parâmetros 
    - `bx_payment_currencie`: Struct do bx_payment_currencie (pode ser %BxPaymentCurrencie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_currencie \ %__MODULE__{}, attrs) do
    bx_payment_currencie
    |> cast(attrs, [:code, :rate])
    |> validate_required([:code])
    |> unique_constraint(:code)
  end

  @doc """
  Changeset para atualização de um bx_payment_currencie existente.

  ## Parâmetros 
    - `bx_payment_currencie`: Struct do bx_payment_currencie (%BxPaymentCurrencie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_currencie \ %__MODULE__{}, attrs) do
    bx_payment_currencie
    |> cast(attrs, [:code, :rate])
    |> unique_constraint(:code)
  end
end
