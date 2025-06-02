defmodule DeeperHub.Schema.BxPaymentModule do
  @moduledoc """
  Schema para representação de bx_payment_modules no sistema

  Este schema armazena as informações de um bx_payment_module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_modules" do
    field :name, :string, default: ""  # varchar(32)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_module no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_module.

  ## Parâmetros 
    - `bx_payment_module`: Struct do bx_payment_module (pode ser %BxPaymentModule{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_module \ %__MODULE__{}, attrs) do
    bx_payment_module
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_payment_module existente.

  ## Parâmetros 
    - `bx_payment_module`: Struct do bx_payment_module (%BxPaymentModule{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_module \ %__MODULE__{}, attrs) do
    bx_payment_module
    |> cast(attrs, [:name])
    |> unique_constraint(:name)
  end
end
