defmodule DeeperHub.Schema.BxPaymentCart do
  @moduledoc """
  Schema para representação de bx_payment_carts no sistema

  Este schema armazena as informações de um bx_payment_cart.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_cart" do
    field :client_id, :integer, default: 0  # int(11)
    field :items, :string, default: "''"  # text
    field :customs, :string, default: "''"  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_cart no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    client_id: integer() | nil,
    items: String.t() | nil,
    customs: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_cart.

  ## Parâmetros 
    - `bx_payment_cart`: Struct do bx_payment_cart (pode ser %BxPaymentCart{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_cart \ %__MODULE__{}, attrs) do
    bx_payment_cart
    |> cast(attrs, [:client_id, :items, :customs])
  end

  @doc """
  Changeset para atualização de um bx_payment_cart existente.

  ## Parâmetros 
    - `bx_payment_cart`: Struct do bx_payment_cart (%BxPaymentCart{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_cart \ %__MODULE__{}, attrs) do
    bx_payment_cart
    |> cast(attrs, [:client_id, :items, :customs])
  end
end
