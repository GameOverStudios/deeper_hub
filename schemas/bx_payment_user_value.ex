defmodule DeeperHub.Schema.BxPaymentUserValue do
  @moduledoc """
  Schema para representação de bx_payment_user_values no sistema

  Este schema armazena as informações de um bx_payment_user_value.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_user_values" do
    field :user_id, :integer, default: 0  # int(11)
    field :option_id, :integer, default: 0  # int(11)
    field :value, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_user_value no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    user_id: integer() | nil,
    option_id: integer() | nil,
    value: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_user_value.

  ## Parâmetros 
    - `bx_payment_user_value`: Struct do bx_payment_user_value (pode ser %BxPaymentUserValue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_user_value \ %__MODULE__{}, attrs) do
    bx_payment_user_value
    |> cast(attrs, [:user_id, :option_id, :value])
    |> validate_required([:value])
  end

  @doc """
  Changeset para atualização de um bx_payment_user_value existente.

  ## Parâmetros 
    - `bx_payment_user_value`: Struct do bx_payment_user_value (%BxPaymentUserValue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_user_value \ %__MODULE__{}, attrs) do
    bx_payment_user_value
    |> cast(attrs, [:user_id, :option_id, :value])
  end
end
